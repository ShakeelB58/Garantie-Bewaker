// Maakt de ruwe schermafbeeldingen voor de App Store en Google Play.
//
// Geen gewone test: draait alleen via de GitHub-workflow "Schermafbeeldingen"
// (of lokaal met `flutter test screenshots`). De afbeeldingen komen in
// `screenshots/raw/` en bevatten alleen fictieve gegevens (DemoData).
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:garantiebewaker/app/router.dart';
import 'package:garantiebewaker/app/theme/app_colors.dart';
import 'package:garantiebewaker/features/demo/demo_data.dart';
import 'package:garantiebewaker/features/documents/domain/document.dart';
import 'package:garantiebewaker/features/documents/presentation/scanner_screen.dart';
import 'package:garantiebewaker/features/products/presentation/new_product_args.dart';
import 'package:garantiebewaker/features/recognition/domain/parsed_receipt.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../test/helpers/document_fakes.dart';
import '../test/helpers/fixtures.dart';
import '../test/helpers/in_memory_product_repository.dart';
import '../test/helpers/test_app.dart';

/// Een toestel waarvoor schermafbeeldingen worden gemaakt.
class _Device {
  const _Device({
    required this.name,
    required this.platform,
    required this.physicalSize,
    required this.pixelRatio,
    required this.top,
    required this.bottom,
  });

  final String name;
  final TargetPlatform platform;
  final Size physicalSize;
  final double pixelRatio;

  /// Statusbalk en thuisbalk, in logische pixels.
  final double top;
  final double bottom;
}

const _devices = [
  // iPhone 6,9 inch (App Store Connect): 1320×2868.
  _Device(
    name: 'ios',
    platform: TargetPlatform.iOS,
    physicalSize: Size(1320, 2868),
    pixelRatio: 3,
    top: 62,
    bottom: 34,
  ),
  // Android-telefoon, 1080×2400.
  _Device(
    name: 'android',
    platform: TargetPlatform.android,
    physicalSize: Size(1080, 2400),
    pixelRatio: 2.625,
    top: 28,
    bottom: 24,
  ),
];

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

String _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  final exe = Platform.resolvedExecutable;
  final index = exe.indexOf(
    '${Platform.pathSeparator}bin${Platform.pathSeparator}cache',
  );
  if (index < 0) throw StateError('FLUTTER_ROOT niet gevonden');
  return exe.substring(0, index);
}

Future<void> _setDevice(WidgetTester tester, _Device device) async {
  tester.view.physicalSize = device.physicalSize;
  tester.view.devicePixelRatio = device.pixelRatio;
  tester.view.padding = FakeViewPadding(
    top: device.top * device.pixelRatio,
    bottom: device.bottom * device.pixelRatio,
  );
  tester.view.viewPadding = FakeViewPadding(
    top: device.top * device.pixelRatio,
    bottom: device.bottom * device.pixelRatio,
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, _Device device, String name) async {
  await tester.pumpAndSettle();
  final element = find.byType(MaterialApp).evaluate().single;
  await tester.runAsync(() async {
    final image = await captureImage(element);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('screenshots/raw/${device.name}/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

/// Start de app met voorbeeldgegevens op het gekozen toestel.
Future<InMemoryProductRepository> _startWithDemo(
  WidgetTester tester,
  _Device device, {
  Widget? scannerPreview,
}) async {
  final repo = await pumpApp(
    tester,
    repository: InMemoryProductRepository(),
    documents: InMemoryDocumentRepository(),
    scannerPreview: scannerPreview,
    showDemoOption: false,
  );
  await _setDevice(tester, device);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  await container.read(demoDataLoaderProvider).load();
  await tester.pumpAndSettle();
  return repo;
}

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('nl');
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('MaterialIcons', [
      '${_flutterRoot()}/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf',
    ]);
  });

  for (final device in _devices) {
    void shoot(
      String description,
      Future<void> Function(WidgetTester tester) body,
    ) async {
      testWidgets('${device.name}: $description', (tester) async {
        debugDefaultTargetPlatformOverride = device.platform;
        debugDisableShadows = false;
        try {
          await body(tester);
        } finally {
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    shoot('1 home', (tester) async {
      await _startWithDemo(tester, device);
      await _capture(tester, device, '1-home');
    });

    shoot('2 scannen', (tester) async {
      await _startWithDemo(
        tester,
        device,
        scannerPreview: const _TableWithReceipt(),
      );
      unawaited(
        Navigator.of(_context(tester), rootNavigator: true).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => const ScannerScreen(),
          ),
        ),
      );
      await _capture(tester, device, '2-scannen');
    });

    shoot('3 controleren', (tester) async {
      await _startWithDemo(tester, device);
      final day = DateTime(testNow.year, testNow.month, testNow.day);
      unawaited(
        GoRouter.of(_context(tester)).push(
          AppRoutes.newProduct,
          extra: NewProductArgs(
            documents: const [
              StagedDocument(
                id: 'staged-1',
                filePath: 'documents/staged-1.pdf',
                format: DocumentFormat.pdf,
                type: DocumentType.receipt,
                sizeBytes: 182000,
                originalFilename: 'Kassabon.pdf',
              ),
            ],
            recognition: ParsedReceipt(
              merchant: const RecognizedField(
                'Elektro Noord',
                RecognitionConfidence.high,
              ),
              purchaseDate: RecognizedField(day, RecognitionConfidence.high),
              totalMinor: const RecognizedField(
                14900,
                RecognitionConfidence.high,
              ),
              productName: const RecognizedField(
                'Draadloze koptelefoon',
                RecognitionConfidence.medium,
              ),
              lineItems: const [
                ParsedLineItem(
                  description: 'Draadloze koptelefoon',
                  amountMinor: 14900,
                ),
              ],
            ),
          ),
        ),
      );
      await _capture(tester, device, '3-controleren');
    });

    shoot('4 product', (tester) async {
      final repo = await _startWithDemo(tester, device);
      final products = await repo.getAll();
      final phone = products.firstWhere((p) => p.name.startsWith('Smartphone'));
      unawaited(
        GoRouter.of(_context(tester)).push(AppRoutes.productDetail(phone.id)),
      );
      await tester.pumpAndSettle();
      final details = find.text('Gegevens');
      if (details.evaluate().isNotEmpty) {
        await tester.tap(details.first);
      }
      await _capture(tester, device, '4-product');
    });

    shoot('5 herinneringen', (tester) async {
      await _startWithDemo(tester, device);
      unawaited(GoRouter.of(_context(tester)).push(AppRoutes.reminders));
      await _capture(tester, device, '5-herinneringen');
    });

    shoot('6 privacy', (tester) async {
      await _startWithDemo(tester, device);
      await tester.tap(find.byKey(const Key('nav.settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy'));
      await _capture(tester, device, '6-privacy');
    });
  }
}

/// Een fictieve kassabon op tafel, in plaats van het camerabeeld.
class _TableWithReceipt extends StatelessWidget {
  const _TableWithReceipt();

  @override
  Widget build(BuildContext context) {
    const line = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      height: 1.5,
      color: Color(0xFF2B2B2B),
    );
    Widget row(String left, String right, {bool bold = false}) => Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: line.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          right,
          style: line.copyWith(
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
    const divider = Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '- - - - - - - - - - - - - - - - - - - - - - -',
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.1,
          colors: [Color(0xFF5B5550), Color(0xFF2E2A27)],
        ),
      ),
      child: Center(
        child: Transform.rotate(
          angle: -0.025,
          child: Container(
            width: 250,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAF6),
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ELEKTRO NOORD',
                  style: line.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text('Voorbeeldstraat 1', style: line),
                const Text('1234 AB Voorbeeldstad', style: line),
                divider,
                row('19-10-2026', '14:32'),
                divider,
                row('Draadloze koptelefoon', '149,00'),
                row('  1 x 149,00', ''),
                divider,
                row('TOTAAL', 'EUR 149,00', bold: true),
                row('Pin', '149,00'),
                row('Btw 21%', '25,86'),
                divider,
                Text(
                  'Bedankt voor je aankoop!',
                  style: line.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
