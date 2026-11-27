import 'package:drift_flutter/drift_flutter.dart';
import 'package:excellium_core/excellium_core.dart';
import 'package:excellium_storage_drift/excellium_storage_drift.dart';
import 'package:path_provider/path_provider.dart';

/// Ouvre le stockage de l'application.
///
/// C'est le seul fichier de l'application qui connaît Drift. Pour changer de
/// moteur de stockage, on remplace cette fonction par une autre qui renvoie
/// un [ExcelliumStore] ; rien d'autre n'est à modifier dans l'application.
/// Le test `architecture_test.dart` vérifie cette règle.
///
/// La base est rangée dans le dossier de données de l'application (et non
/// dans « Documents »). La fonction lit une première fois le classeur pour
/// que toute erreur d'ouverture remonte ici, au démarrage, plutôt que de
/// laisser l'écran attendre indéfiniment.
Future<ExcelliumStore> openStore() async {
  final store = DriftStore(
    driftDatabase(
      name: 'excellium',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    ),
  );
  try {
    await store.sheets.getSheets();
  } catch (_) {
    await store.close();
    rethrow;
  }
  return store;
}
