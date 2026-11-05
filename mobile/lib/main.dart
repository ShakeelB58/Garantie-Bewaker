import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';
import 'l10n/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Maand- en dagnamen voor datumnotatie buiten Material-widgets.
  await initializeDateFormatting();
  // Nederlands als de telefoon op Nederlands staat, anders Engels.
  AppLocale.apply(WidgetsBinding.instance.platformDispatcher.locale);
  // Nodig om PDF's te lezen buiten de PDF-viewer (tekstextractie).
  await pdfrxFlutterInitialize();
  // Licentie van het lettertype Poppins tonen bij "Licenties".
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Poppins'], text);
  });
  runApp(const ProviderScope(child: BonvrijApp()));
}
