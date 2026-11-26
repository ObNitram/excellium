import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/excellium_app.dart';
import 'app/startup_error_app.dart';
import 'bootstrap/formulas.dart';
import 'bootstrap/storage.dart';
import 'shared/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Racine de composition : c'est ici, et seulement ici, que le moteur de
  // stockage et le moteur de formules concrets sont choisis puis injectés.
  final ExcelliumStore store;
  try {
    store = await openStore();
  } catch (error) {
    runApp(StartupErrorApp(error: error));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        formulaEngineProvider.overrideWithValue(createFormulaEngine()),
      ],
      child: const ExcelliumApp(),
    ),
  );
}
