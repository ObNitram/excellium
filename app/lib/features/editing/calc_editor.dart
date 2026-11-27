import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/providers.dart';
import '../../shared/workbook_fields.dart';
import '../formulas/formula_text.dart';
import '../grid/grid_providers.dart';

/// Champ de saisie d'une formule ou d'un calcul, avec son message d'erreur.
///
/// Le texte est enregistré à chaque frappe. Le champ fait foi : il n'est
/// réaligné sur la valeur enregistrée que lorsque [identity] change (on a
/// choisi une autre colonne ou une autre case), pour ne jamais écraser ce
/// qui est en train d'être tapé.
class _FormulaField extends StatefulWidget {
  const _FormulaField({
    super.key,
    required this.identity,
    required this.text,
    required this.onChanged,
    required this.label,
    required this.hint,
    required this.error,
    this.autofocus = false,
    this.focusSignal = 0,
    this.leading,
    this.trailing = const [],
    this.note,
  });

  /// Ce que le champ édite ; un changement recharge le texte.
  final String identity;
  final String text;
  final ValueChanged<String> onChanged;

  /// Nom du champ pour l'accessibilité.
  final String label;
  final String hint;
  final FormulaError? error;

  /// Vrai pour prendre le focus dès que [identity] change.
  final bool autofocus;

  /// Le champ reprend le focus chaque fois que cette valeur change : c'est
  /// le compteur des clics sur une case (voir [editRequestProvider]).
  final int focusSignal;
  final Widget? leading;

  /// Boutons placés après le champ ; ils reçoivent de quoi y écrire.
  final List<Widget> trailing;

  /// Précision affichée quand il n'y a pas d'erreur.
  final String? note;

  @override
  State<_FormulaField> createState() => _FormulaFieldState();
}

class _FormulaFieldState extends State<_FormulaField> {
  late final _controller = TextEditingController(text: widget.text);
  final _focus = FocusNode();

  /// Vrai entre le moment où le champ demande le focus de lui-même et celui
  /// où il l'obtient.
  bool _caretToEnd = false;

  @override
  void initState() {
    super.initState();
    // Chaque frappe est enregistrée : Ctrl+Z annule dans le classeur, où
    // la saisie compte pour une seule modification.
    WorkbookFields.register(_focus);
    _focus.addListener(_onFocusChanged);
    if (widget.autofocus) _takeFocus();
  }

  /// Prend la saisie, le curseur à la fin du texte : on complète la formule.
  ///
  /// Sur ordinateur, un champ qui reçoit le focus sans qu'on ait cliqué
  /// dedans sélectionne tout son texte. Ici chaque frappe est enregistrée :
  /// une touche effacerait la formule de toute la colonne. On replace donc
  /// le curseur à la fin, mais seulement quand c'est le champ qui a demandé
  /// le focus, pas quand on clique dedans pour choisir où écrire.
  void _takeFocus() {
    if (!_focus.hasFocus) _caretToEnd = true;
    _focus.requestFocus();
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus || !_caretToEnd) return;
    _caretToEnd = false;
    // Après la sélection automatique du champ, faite sur ce même évènement.
    Future.microtask(() {
      if (!mounted) return;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  @override
  void didUpdateWidget(_FormulaField old) {
    super.didUpdateWidget(old);
    // Tant qu'on édite la même chose, le champ fait foi : la valeur
    // enregistrée arrive avec un temps de retard, et la recopier ici
    // effacerait ce qui vient d'être tapé ou inséré.
    if (old.identity != widget.identity) {
      _echoes.clear();
      _controller.text = widget.text;
      if (widget.autofocus) _takeFocus();
    } else if (widget.text != old.text &&
        widget.text != _controller.text &&
        !_echoes.contains(widget.text)) {
      // Le texte enregistré a changé sans venir de ce champ (Ctrl+Z, par
      // exemple) : le champ le reprend.
      _echoes.clear();
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
    // Un clic sur la case, même déjà sélectionnée, rend la saisie au champ :
    // à la souris, cliquer hors du champ lui retire le focus.
    if (old.focusSignal != widget.focusSignal) _takeFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    WorkbookFields.unregister(_focus);
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  /// Ajoute [text] à la fin du champ, pour les boutons de fonction.
  void append(String text) {
    final next = _controller.text + text;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _save(next);
    _takeFocus();
  }

  /// Textes envoyés à l'enregistrement depuis le dernier chargement. Ils
  /// reviennent avec un temps de retard, parfois dans le désordre : les
  /// reconnaître évite d'écraser ce qui est en train d'être tapé.
  final Set<String> _echoes = {};

  void _save(String text) {
    _echoes.add(text);
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: error == null ? AppColors.fieldBorder : AppColors.danger,
        width: error == null ? 1 : 2,
      ),
    );
    // Le message d'erreur est sur la même ligne que le champ : la barre garde
    // sa hauteur, et la grille ne saute pas à chaque caractère pendant la
    // saisie, où presque tous les états intermédiaires sont des erreurs.
    return Row(
      children: [
        ?widget.leading,
        Expanded(
          flex: 3,
          child: Semantics(
            label: widget.label,
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _save,
                autocorrect: false,
                enableSuggestions: false,
                textAlignVertical: TextAlignVertical.center,
                style: AppText.mono.copyWith(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppText.mono.copyWith(color: AppColors.textMuted),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: BorderSide(
                      color: error == null
                          ? AppColors.accent
                          : AppColors.danger,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Semantics(
              liveRegion: true,
              child: Tooltip(
                message: formulaErrorMessage(error),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(
                      AppIcons.error,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        formulaErrorMessage(error),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (widget.note != null) ...[
          const SizedBox(width: 10),
          Text(
            widget.note!,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        // Les boutons font partie du champ : cliquer dessus à la souris ne
        // lui retire pas le focus.
        for (final button in widget.trailing) TextFieldTapRegion(child: button),
      ],
    );
  }
}

/// Éditeur de la formule d'une colonne Formule. La formule vaut pour toutes
/// les lignes : on la retrouve en sélectionnant une cellule ou la colonne.
class FormulaEditor extends ConsumerWidget {
  const FormulaEditor({super.key, required this.column});

  final ColumnDef column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = ref
        .watch(sheetFormulasProvider(column.sheetId))
        .column(column.id);
    return _FormulaField(
      key: const Key('formula-editor'),
      identity: column.id.value,
      text: column.formula,
      onChanged: (text) =>
          ref.read(workbookServiceProvider).setFormula(column, text),
      label: 'Formule de la colonne',
      hint: 'Quantité × Prix',
      // Le champ prend le focus dès que la colonne est choisie : on écrit la
      // formule tout de suite après avoir donné le type Formule.
      autofocus: true,
      focusSignal: ref.watch(editRequestProvider),
      error: values.error,
      note: 'Calculée pour chaque ligne de la colonne',
      leading: const Padding(
        padding: EdgeInsets.only(right: 10),
        child: Text(
          '=',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Éditeur d'une case de calcul : en bas de la grille, ou sur une ligne de
/// regroupement. Le contenu est un texte, ou un calcul qui commence par `=`.
class CalcEditor extends ConsumerStatefulWidget {
  const CalcEditor({super.key, required this.column, required this.selection});

  final ColumnDef column;

  /// Une [CalcCellSelected] ou une [GroupCalcSelected].
  final GridSelection selection;

  @override
  ConsumerState<CalcEditor> createState() => _CalcEditorState();
}

class _CalcEditorState extends ConsumerState<CalcEditor> {
  final _field = GlobalKey<_FormulaFieldState>();

  @override
  Widget build(BuildContext context) {
    final column = widget.column;
    final selection = widget.selection;
    final service = ref.read(workbookServiceProvider);
    final formulas = ref.watch(sheetFormulasProvider(column.sheetId));

    final String text;
    final String identity;
    final ValueChanged<String> save;
    if (selection is CalcCellSelected) {
      text = column.calcCells[selection.index] ?? '';
      identity = 'calc-${column.id.value}-${selection.index}';
      save = (next) => service.setCalcCell(column, selection.index, next);
    } else {
      // Le contenu est le même pour tous les groupes : changer de groupe ne
      // recharge pas le champ.
      text = column.groupCalc;
      identity = 'group-${column.id.value}';
      save = (next) => service.setGroupCalc(column, next);
    }
    // L'erreur ne dépend pas des lignes : on l'évalue sur toute la table.
    final display = calcDisplay(formulas.calcCell(text));

    return _FormulaField(
      key: _field,
      identity: identity,
      text: text,
      onChanged: save,
      label: 'Contenu de la case de calcul',
      hint: 'Texte, ou calcul : =Somme(Budget)',
      error: display.error,
      autofocus: true,
      focusSignal: ref.watch(editRequestProvider),
      trailing: [
        for (final function in formulas.functions)
          if (function.kind == FormulaFunctionKind.column)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: OutlinedButton(
                style:
                    OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.standard,
                      minimumSize: const Size(0, 28),
                      maximumSize: const Size(double.infinity, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: AppColors.text,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.fieldBorder),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ).copyWith(
                      overlayColor: const WidgetStatePropertyAll(
                        AppColors.hover,
                      ),
                    ),
                onPressed: () {
                  final field = _field.currentState;
                  if (field == null) return;
                  final current = field._controller.text;
                  final lead = current.trim().isEmpty
                      ? calcPrefix
                      : (RegExp(r'[=(\s]$').hasMatch(current) ? '' : ' ');
                  field.append('$lead${function.name}(');
                },
                child: Text(function.name),
              ),
            ),
      ],
    );
  }
}
