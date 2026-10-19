import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/documents/application/document_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class GarantieBewakerApp extends ConsumerStatefulWidget {
  const GarantieBewakerApp({super.key});

  @override
  ConsumerState<GarantieBewakerApp> createState() => _GarantieBewakerAppState();
}

class _GarantieBewakerAppState extends ConsumerState<GarantieBewakerApp> {
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
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GarantieBewaker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      // Alle gebruikersgerichte tekst is Nederlands, ook standaardteksten van
      // Material-componenten zoals datumkiezers.
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
