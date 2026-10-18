import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class GarantieBewakerApp extends ConsumerWidget {
  const GarantieBewakerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
