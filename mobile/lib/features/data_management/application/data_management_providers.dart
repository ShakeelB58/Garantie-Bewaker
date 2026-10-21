import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/storage/storage_providers.dart';
import '../../documents/application/document_service.dart';
import '../../products/application/product_providers.dart';
import '../../reminders/application/reminder_service.dart';
import '../../settings/application/settings_providers.dart';
import '../data/export_saver.dart';
import 'data_wipe_service.dart';
import 'export_service.dart';

final exportSaverProvider = Provider<ExportSaver>((ref) => SystemExportSaver());

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(
    products: ref.watch(productRepositoryProvider),
    documents: ref.watch(documentRepositoryProvider),
    fileStore: ref.watch(documentFileStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

final dataWipeServiceProvider = Provider<DataWipeService>(
  (ref) => DataWipeService(
    products: ref.watch(productRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    fileStore: ref.watch(documentFileStoreProvider),
    notifications: ref.watch(reminderNotificationsProvider),
    picker: ref.watch(documentPickerProvider),
  ),
);

/// Versie van de app, bijv. "0.1.0 (1)".
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// Verwijdert alles en ververst de schermen.
Future<void> wipeAllData(WidgetRef ref) async {
  await ref.read(dataWipeServiceProvider).wipeAll();
  ref
    ..invalidate(productsProvider)
    ..invalidate(reminderLeadProvider)
    ..invalidate(documentsForProductProvider)
    ..invalidate(allDocumentsProvider)
    ..invalidate(documentByIdProvider)
    ..invalidate(notificationsEnabledProvider);
}
