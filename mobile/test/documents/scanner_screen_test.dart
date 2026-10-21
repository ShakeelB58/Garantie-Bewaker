import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garantiebewaker/features/documents/application/document_service.dart';
import 'package:garantiebewaker/features/documents/data/camera_scanner.dart';
import 'package:garantiebewaker/features/documents/data/document_picker.dart';
import 'package:garantiebewaker/features/documents/presentation/scanner_screen.dart';

import '../helpers/document_fakes.dart';

/// In tests is er geen camera, net als op de iOS-simulator. Dan moet de
/// scanner een duidelijke melding tonen en de fotobibliotheek aanbieden.
void main() {
  testWidgets('zonder camera: melding en kiezen uit foto\'s', (tester) async {
    final picker = FakeDocumentPicker()
      ..results.add(const PickedFile(path: '/tmp/bon.jpg'));
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentPickerProvider.overrideWithValue(picker),
          availableCamerasProvider.overrideWithValue(() async => []),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const SizedBox.shrink(),
        ),
      ),
    );

    final result = InAppCameraScanner().scan(navigatorKey.currentState!);
    await tester.pumpAndSettle();

    expect(find.text('Kassabon scannen'), findsOneWidget);
    expect(
      find.text('Er is geen camera beschikbaar op dit toestel.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Kiezen uit foto\'s'));
    await tester.pumpAndSettle();

    final ScanResult? scan = await result;
    expect(scan?.file.path, '/tmp/bon.jpg');
    expect(scan?.fromGallery, isTrue);
    expect(picker.requests, [DocumentSource.gallery]);
  });

  testWidgets('sluiten geeft geen resultaat', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentPickerProvider.overrideWithValue(FakeDocumentPicker()),
          availableCamerasProvider.overrideWithValue(() async => []),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const SizedBox.shrink(),
        ),
      ),
    );

    final result = InAppCameraScanner().scan(navigatorKey.currentState!);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sluiten'));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
