import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nederlandse maand- en dagnamen voor datumnotatie buiten Material-widgets.
  await initializeDateFormatting('nl');
  // Nodig om PDF's te lezen buiten de PDF-viewer (tekstextractie).
  await pdfrxFlutterInitialize();
  runApp(const ProviderScope(child: BonvrijApp()));
}
