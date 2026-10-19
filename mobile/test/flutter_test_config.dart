import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Wordt door `flutter test` automatisch vóór alle tests in deze map uitgevoerd.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting('nl');
  await testMain();
}
