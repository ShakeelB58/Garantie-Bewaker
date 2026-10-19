import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

/// De lokale database. In tests wordt deze overschreven.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.device();
  ref.onDispose(database.close);
  return database;
});

/// Huidig tijdstip. In tests vervangen door een vaste klok.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Nieuwe UUID's voor entiteiten.
final idGeneratorProvider = Provider<String Function()>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});
