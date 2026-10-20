import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/core/errors/user_message.dart';
import 'package:garantiebewaker/features/documents/application/document_service.dart';
import 'package:garantiebewaker/features/documents/data/document_picker.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/documents/domain/document_validation.dart';

import '../helpers/document_fakes.dart';
import '../helpers/fixtures.dart';

void main() {
  late InMemoryDocumentRepository repository;
  late InMemoryDocumentFileStore fileStore;
  late DocumentService service;
  var nextId = 0;

  setUp(() {
    repository = InMemoryDocumentRepository();
    fileStore = InMemoryDocumentFileStore();
    nextId = 0;
    service = DocumentService(
      repository: repository,
      fileStore: fileStore,
      newId: () => 'doc-${nextId++}',
      clock: () => testNow,
    );
  });

  group('stage', () {
    test(
      'PDF wordt opgeslagen als factuur en de tijdelijke kopie verdwijnt',
      () async {
        fileStore.addSource('/tmp/f.pdf', pdfBytes);

        final staged = await service.stage(
          const PickedFile(path: '/tmp/f.pdf', originalName: 'Factuur 12.pdf'),
        );

        expect(staged.filePath, 'documents/doc-0.pdf');
        expect(staged.format, DocumentFormat.pdf);
        expect(staged.type, DocumentType.invoice);
        expect(staged.originalFilename, 'Factuur 12.pdf');
        expect(staged.sizeBytes, pdfBytes.length);
        expect(fileStore.stored['documents/doc-0.pdf'], pdfBytes);
        expect(fileStore.sources, isEmpty);
        // Nog niet gekoppeld aan een product.
        expect(repository.all, isEmpty);
      },
    );

    test('foto wordt kassabon; type kan worden opgegeven', () async {
      fileStore
        ..addSource('/tmp/a.jpg', jpegBytes)
        ..addSource('/tmp/b.jpg', jpegBytes);

      final a = await service.stage(const PickedFile(path: '/tmp/a.jpg'));
      final b = await service.stage(
        const PickedFile(path: '/tmp/b.jpg'),
        type: DocumentType.warranty,
      );

      expect(a.type, DocumentType.receipt);
      expect(a.filePath, endsWith('.jpg'));
      expect(b.type, DocumentType.warranty);
    });

    test('origineel van de gebruiker blijft staan', () async {
      fileStore.addSource('/Downloads/f.pdf', pdfBytes, temporary: false);
      await service.stage(const PickedFile(path: '/Downloads/f.pdf'));
      expect(fileStore.sources.keys, ['/Downloads/f.pdf']);
    });

    test(
      'niet-ondersteund bestand: duidelijke melding, niets opgeslagen',
      () async {
        fileStore.addSource('/tmp/notitie.pdf', textBytes);

        await expectLater(
          service.stage(const PickedFile(path: '/tmp/notitie.pdf')),
          throwsA(
            isA<AppException>().having(
              (e) => e.userMessage,
              'melding',
              contains('niet ondersteund'),
            ),
          ),
        );
        expect(fileStore.stored, isEmpty);
        // Ook bij een fout wordt de tijdelijke kopie opgeruimd.
        expect(fileStore.sources, isEmpty);
      },
    );

    test('te groot bestand', () async {
      final big = Uint8List(DocumentValidation.maxSizeBytes + 1)
        ..setRange(0, pdfBytes.length, pdfBytes);
      fileStore.addSource('/tmp/groot.pdf', big);

      await expectLater(
        service.stage(const PickedFile(path: '/tmp/groot.pdf')),
        throwsA(isA<AppException>()),
      );
      expect(fileStore.stored, isEmpty);
    });

    test('onleesbaar bestand', () async {
      await expectLater(
        service.stage(const PickedFile(path: '/bestaat/niet.pdf')),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'melding',
            'Het bestand kon niet worden gelezen.',
          ),
        ),
      );
    });
  });

  test('attach koppelt aan een product', () async {
    fileStore.addSource('/tmp/f.pdf', pdfBytes);
    final staged = await service.stage(
      const PickedFile(path: '/tmp/f.pdf', originalName: 'f.pdf'),
    );

    final document = await service.attach(staged, 'p1');

    expect(repository.all, [document]);
    expect(document.productId, 'p1');
    expect(document.filePath, staged.filePath);
    expect(document.createdAt.isUtc, isTrue);
  });

  test('discard verwijdert het opgeslagen bestand', () async {
    fileStore.addSource('/tmp/f.pdf', pdfBytes);
    final staged = await service.stage(const PickedFile(path: '/tmp/f.pdf'));

    await service.discard(staged);

    expect(fileStore.stored, isEmpty);
  });

  test('delete verwijdert record en bestand', () async {
    final document = makeDocument();
    await repository.insert(document);
    fileStore.addStored(document.filePath, pdfBytes);

    await service.delete(document);

    expect(repository.all, isEmpty);
    expect(fileStore.stored, isEmpty);
  });

  test('changeType', () async {
    final document = makeDocument();
    await repository.insert(document);
    await service.changeType(document, DocumentType.warranty);
    expect(repository.all.single.type, DocumentType.warranty);
  });

  test('cleanupOrphans ruimt alleen oude, losse bestanden op', () async {
    final linked = makeDocument(id: 'gekoppeld');
    await repository.insert(linked);
    fileStore
      ..addStored(linked.filePath, pdfBytes, at: DateTime(2026, 1, 1))
      ..addStored('documents/oud-los.pdf', pdfBytes, at: DateTime(2026, 1, 1))
      // Net opgeslagen: mogelijk staat het formulier nog open.
      ..addStored(
        'documents/nieuw-los.pdf',
        pdfBytes,
        at: testNow.subtract(const Duration(minutes: 5)),
      );

    final removed = await service.cleanupOrphans();

    expect(removed, 1);
    expect(
      fileStore.stored.keys,
      unorderedEquals([linked.filePath, 'documents/nieuw-los.pdf']),
    );
  });
}
