import 'package:sqflite/sqflite.dart';
import '../../l10n/app_strings.dart';

/// Fout met een begrijpelijke Nederlandse melding voor de gebruiker.
class AppException implements Exception {
  const AppException(this.userMessage, {this.cause});

  final String userMessage;
  final Object? cause;

  @override
  String toString() => 'AppException: $userMessage';
}

/// Centrale vertaling van technische fouten naar Nederlandse meldingen.
///
/// Technische details (SQL, paden, stacktraces) komen nooit in de melding.
String userMessageFor(Object error) {
  if (error is AppException) return error.userMessage;
  if (error is DatabaseException) {
    return S.current.errorStorage;
  }
  return S.current.errorGeneric;
}
