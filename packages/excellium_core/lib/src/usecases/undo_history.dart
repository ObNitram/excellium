import 'dart:async';

import '../ports/store.dart';

/// Historique des modifications du classeur, pour annuler et rétablir.
///
/// Avant chaque modification, [WorkbookService] demande à l'historique de
/// garder un instantané du classeur ([record]). Annuler remet le dernier
/// instantané en place ; l'état qu'on quitte part dans la pile « rétablir ».
///
/// Les saisies au fil de la frappe (une formule, une case de calcul)
/// enregistrent à chaque caractère : elles portent une clé, et les
/// enregistrements de même clé rapprochés dans le temps n'en font qu'un.
/// Annuler efface alors toute la saisie, pas une lettre.
final class UndoHistory {
  UndoHistory(
    this._store, {
    this.limit = 100,
    this.mergeWindow = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ExcelliumStore _store;

  /// Nombre de modifications qu'on peut annuler.
  final int limit;

  /// Délai sous lequel deux modifications de même clé sont fusionnées.
  final Duration mergeWindow;
  final DateTime Function() _clock;

  final List<WorkbookSnapshot> _undo = [];
  final List<WorkbookSnapshot> _redo = [];
  Object? _lastKey;
  DateTime? _lastAt;
  final StreamController<void> _changes = StreamController.broadcast();

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Émet quand [canUndo] ou [canRedo] peut avoir changé.
  Stream<void> get changes => _changes.stream;

  /// Garde l'état actuel du classeur, juste avant une modification.
  ///
  /// Renvoie vrai si un instantané a été ajouté, faux si la modification
  /// prolonge la précédente (même [mergeKey], peu de temps après).
  Future<bool> record({Object? mergeKey}) async {
    final now = _clock();
    final merged =
        mergeKey != null &&
        mergeKey == _lastKey &&
        _lastAt != null &&
        now.difference(_lastAt!) < mergeWindow &&
        _undo.isNotEmpty;
    _lastKey = mergeKey;
    _lastAt = now;
    if (merged) return false;
    _undo.add(await _store.snapshot());
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
    _changes.add(null);
    return true;
  }

  /// Oublie le dernier instantané : la modification n'a finalement rien
  /// changé (refusée, ou en erreur).
  void discardLast() {
    if (_undo.isEmpty) return;
    _undo.removeLast();
    _lastKey = null;
    _changes.add(null);
  }

  /// Revient à l'état d'avant la dernière modification. Faux s'il n'y a
  /// rien à annuler.
  Future<bool> undo() => _move(_undo, _redo);

  /// Refait la dernière modification annulée. Faux s'il n'y a rien à
  /// rétablir.
  Future<bool> redo() => _move(_redo, _undo);

  Future<bool> _move(
    List<WorkbookSnapshot> from,
    List<WorkbookSnapshot> to,
  ) async {
    if (from.isEmpty) return false;
    final target = from.removeLast();
    to.add(await _store.snapshot());
    await _store.restore(target);
    // Après un retour en arrière, une nouvelle saisie ne se fond pas dans
    // celle d'avant.
    _lastKey = null;
    _changes.add(null);
    return true;
  }

  /// Vide l'historique.
  void clear() {
    _undo.clear();
    _redo.clear();
    _lastKey = null;
    _changes.add(null);
  }

  Future<void> close() => _changes.close();
}
