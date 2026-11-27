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

/// Ce qu'on peut annuler ou rétablir, à jour après chaque modification.
typedef UndoState = ({bool canUndo, bool canRedo});

final undoStateProvider = StreamProvider<UndoState>((ref) async* {
  final history = ref.watch(workbookServiceProvider).history;
  UndoState read() => (canUndo: history.canUndo, canRedo: history.canRedo);
  yield read();
  await for (final _ in history.changes) {
    yield read();
  }
});

/// Zoom de la feuille affichée, gardé le temps de la session.
final zoomProvider = NotifierProvider<Zoom, double>(Zoom.new);

class Zoom extends Notifier<double> {
  /// Niveaux proposés, en fraction de la taille normale.
  static const levels = [0.5, 0.75, 0.9, 1.0, 1.25, 1.5, 2.0];

  @override
  double build() => 1;

  void set(double level) => state = level;

  void zoomIn() {
    for (final level in levels) {
      if (level > state) {
        state = level;
        return;
      }
    }
  }

  void zoomOut() {
    for (final level in levels.reversed) {
      if (level < state) {
        state = level;
        return;
      }
    }
  }

  void reset() => state = 1;
}
