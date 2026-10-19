import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/user_message.dart';
import '../features/documents/application/document_service.dart';
import '../features/documents/data/document_picker.dart';
import '../features/documents/data/incoming_files.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class GarantieBewakerApp extends ConsumerStatefulWidget {
  const GarantieBewakerApp({super.key});

  @override
  ConsumerState<GarantieBewakerApp> createState() => _GarantieBewakerAppState();
}

class _GarantieBewakerAppState extends ConsumerState<GarantieBewakerApp> {
  /// Meldingen tonen vanaf app-niveau (bijv. bij een gedeeld bestand).
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<IncomingFile>? _incomingSubscription;

  @override
  void initState() {
    super.initState();
    // Losse documentbestanden opruimen die nergens meer bij horen (bijv. als
    // de app werd afgesloten tijdens het invullen van een formulier).
    // Fouten hierbij mogen de app nooit blokkeren.
    ref
        .read(documentServiceProvider)
        .cleanupOrphans()
        .then<void>(
          (_) {},
          onError: (Object error) =>
              debugPrint('Opruimen mislukt (${error.runtimeType})'),
        );

    // Bestanden die via "Openen met" of "Delen" binnenkomen.
    _incomingSubscription = ref
        .read(incomingFileSourceProvider)
        .files
        .listen(_onIncomingFile, onError: _showError);
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    super.dispose();
  }

  void _showError(Object error) {
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(userMessageFor(error))));
  }

  /// Controleert en bewaart het gedeelde bestand en opent daarna het
  /// formulier voor een nieuw product, met het document al toegevoegd.
  Future<void> _onIncomingFile(IncomingFile file) async {
    final service = ref.read(documentServiceProvider);
    final fileStore = ref.read(documentFileStoreProvider);
    final source = ref.read(incomingFileSourceProvider);
    final router = ref.read(routerProvider);
    try {
      final staged = await service.stage(
        PickedFile(path: file.path, originalName: file.name),
      );
      // Bij een koude start eerst het eerste scherm laten opbouwen.
      await WidgetsBinding.instance.endOfFrame;
      unawaited(router.push(AppRoutes.newProduct, extra: staged));
    } catch (error) {
      _showError(error);
    } finally {
      final original = file.originalPath;
      if (original != null) await fileStore.deleteIfTemporary(original);
      await source.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GarantieBewaker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      scaffoldMessengerKey: _messengerKey,
      // Alle gebruikersgerichte tekst is Nederlands, ook standaardteksten van
      // Material-componenten zoals datumkiezers.
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
