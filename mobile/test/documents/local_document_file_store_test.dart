import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/documents/data/document_file_store.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:path/path.dart' as p;

import '../helpers/document_fakes.dart';

/// Tests tegen het echte bestandssysteem, in tijdelijke mappen.
void main() {
  late Directory root;
  late Directory base;
  late Directory temp;
  late Directory outside;
  late LocalDocumentFileStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('garantiebewaker_test');
    base = await Directory(p.join(root.path, 'app')).create();
    temp = await Directory(p.join(root.path, 'tmp')).create();
    outside = await Directory(p.join(root.path, 'gebruiker')).create();
    store = LocalDocumentFileStore(
      baseDirectory: () async => base,
      temporaryDirectory: () async => temp,
    );
  });

  tearDown(() => root.delete(recursive: true));

  Future<File> writeFile(Directory dir, String name, List<int> bytes) =>
      File(p.join(dir.path, name)).writeAsBytes(bytes);

  test('inspectSource leest grootte en begin van het bestand', () async {
    final file = await writeFile(outside, 'f.pdf', pdfBytes);
    final info = await store.inspectSource(file.path);
    expect(info.sizeBytes, pdfBytes.length);
    expect(info.header, pdfBytes);
  });

  test('store kopieert naar de app-map en laat het origineel staan', () async {
    final file = await writeFile(outside, 'factuur.pdf', pdfBytes);

    final relative = await store.store(
      file.path,
      id: 'abc-123',
      format: DocumentFormat.pdf,
    );

    expect(relative, 'documents/abc-123.pdf');
    final copy = File(await store.resolve(relative));
    expect(await copy.readAsBytes(), pdfBytes);
    expect(await file.exists(), isTrue);
    // Geen half gekopieerde bestanden achtergebleven.
    expect(
      Directory(p.join(base.path, 'documents')).listSync().map((e) => p.basename(e.path)),
      ['abc-123.pdf'],
    );
  });

  test('resolve weigert onveilige paden', () async {
    for (final bad in [
      '../geheim.pdf',
      'documents/../../geheim.pdf',
      '/etc/passwd',
      'documents/a.exe',
      'documents/',
      'andere/a.pdf',
    ]) {
      await expectLater(
        store.resolve(bad),
        throwsArgumentError,
        reason: bad,
      );
    }
  });

  test('store weigert een onveilig id', () async {
    final file = await writeFile(outside, 'f.pdf', pdfBytes);
    await expectLater(
      store.store(file.path, id: '../x', format: DocumentFormat.pdf),
      throwsArgumentError,
    );
  });

  test('delete verwijdert, en een ontbrekend bestand is geen fout', () async {
    final file = await writeFile(outside, 'f.jpg', jpegBytes);
    final relative = await store.store(
      file.path,
      id: 'd1',
      format: DocumentFormat.jpeg,
    );

    await store.delete(relative);
    expect(await File(await store.resolve(relative)).exists(), isFalse);
    await store.delete(relative);
  });

  test('listStored toont alleen geldige documenten', () async {
    final file = await writeFile(outside, 'f.pdf', pdfBytes);
    await store.store(file.path, id: 'd1', format: DocumentFormat.pdf);
    await writeFile(
      Directory(p.join(base.path, 'documents')),
      'vreemd.txt',
      [1, 2, 3],
    );

    final listed = await store.listStored();
    expect(listed.keys, ['documents/d1.pdf']);
  });

  test('deleteIfTemporary raakt alleen bestanden in de tijdelijke map', () async {
    final tempFile = await writeFile(temp, 'camera.jpg', jpegBytes);
    final userFile = await writeFile(outside, 'foto.jpg', jpegBytes);

    await store.deleteIfTemporary(tempFile.path);
    await store.deleteIfTemporary(userFile.path);
    // Een pad dat via ../ uit de tijdelijke map ontsnapt, telt niet.
    await store.deleteIfTemporary(
      p.join(temp.path, '..', 'gebruiker', 'foto.jpg'),
    );

    expect(await tempFile.exists(), isFalse);
    expect(await userFile.exists(), isTrue);
  });
}
