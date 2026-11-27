import 'package:material_ui/material_ui.dart';

/// Champs de saisie qui écrivent dans le classeur : la barre d'édition, les
/// éditeurs de formule et de case de calcul.
///
/// Quand l'un d'eux a le focus et qu'aucune saisie n'y est en cours,
/// Ctrl+Z annule la dernière modification du classeur, comme dans un
/// tableur. Dans les autres champs (recherche, filtre, renommage), ou pendant
/// une saisie, Ctrl+Z annule la frappe.
abstract final class WorkbookFields {
  static final Map<FocusNode, bool Function()> _fields = {};

  /// Déclare [node] ; [pending] dit si une saisie y est en cours (texte
  /// tapé mais pas encore validé).
  static void register(FocusNode node, {bool Function()? pending}) =>
      _fields[node] = pending ?? () => false;

  static void unregister(FocusNode node) => _fields.remove(node);

  /// Vrai si Ctrl+Z et Ctrl+Y doivent agir sur le classeur plutôt que sur
  /// le champ qui a le focus.
  static bool undoesWorkbook(FocusNode? focus) {
    final context = focus?.context;
    if (focus == null || context == null) return true;
    final inField =
        context.widget is EditableText ||
        context.findAncestorStateOfType<EditableTextState>() != null;
    if (!inField) return true;
    final pending = _fields[focus];
    return pending != null && !pending();
  }
}
