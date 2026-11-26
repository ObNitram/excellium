import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le stockage de l'application, vu à travers son interface.
///
/// Il est fourni au démarrage (`main.dart`) et remplacé par un stockage en
/// mémoire dans les tests.
final storeProvider = Provider<ExcelliumStore>(
  (ref) => throw UnimplementedError(
    'storeProvider doit être surchargé au démarrage de l\'application.',
  ),
);

/// Le moteur de formules, vu à travers son interface. Fourni au démarrage,
/// comme le stockage.
final formulaEngineProvider = Provider<FormulaEngine>(
  (ref) => throw UnimplementedError(
    'formulaEngineProvider doit être surchargé au démarrage de l\'application.',
  ),
);

/// Les cas d'usage du classeur.
final workbookServiceProvider = Provider<WorkbookService>(
  (ref) => WorkbookService(ref.watch(storeProvider)),
);
