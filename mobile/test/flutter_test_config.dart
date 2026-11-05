import 'dart:async';
import 'dart:ui';

import 'package:garantiebewaker/l10n/app_locale.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Wordt door `flutter test` automatisch vóór alle tests in deze map uitgevoerd.
/// Standaard draaien de tests in het Nederlands; Engelse tests zetten de taal
/// zelf om met [AppLocale.apply] (en terug in `tearDown`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  AppLocale.apply(const Locale('nl', 'NL'));
  await testMain();
}
