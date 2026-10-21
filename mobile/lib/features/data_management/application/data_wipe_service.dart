import 'package:flutter/foundation.dart';

import '../../documents/data/document_file_store.dart';
import '../../documents/data/document_picker.dart';
import '../../products/data/product_repository.dart';
import '../../reminders/data/reminder_notifications.dart';
import '../../settings/data/settings_repository.dart';

/// Verwijdert alle gegevens die GarantieBewaker op het toestel heeft
/// opgeslagen. Er is geen server, dus daarna is er nergens meer een kopie
/// (behalve een export die de gebruiker zelf heeft bewaard).
class DataWipeService {
  DataWipeService({
    required ProductRepository products,
    required SettingsRepository settings,
    required DocumentFileStore fileStore,
    required ReminderNotifications notifications,
    required DocumentPicker picker,
  }) : _products = products,
       _settings = settings,
       _fileStore = fileStore,
       _notifications = notifications,
       _picker = picker;

  final ProductRepository _products;
  final SettingsRepository _settings;
  final DocumentFileStore _fileStore;
  final ReminderNotifications _notifications;
  final DocumentPicker _picker;

  /// Volgorde: eerst de database (daarna toont de app niets meer), dan de
  /// bestanden. Lukt het verwijderen van een bestand niet, dan ruimt de
  /// opstartcontrole het later alsnog op, omdat het nergens meer bij hoort.
  Future<void> wipeAll() async {
    await _products.deleteAll();
    await _settings.clear();
    await _quietly(_notifications.cancelAll);
    await _quietly(_fileStore.deleteAll);
    await _quietly(_picker.clearTemporaryFiles);
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Verwijderen mislukt (${error.runtimeType})');
    }
  }
}
