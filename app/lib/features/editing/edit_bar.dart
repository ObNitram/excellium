import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/providers.dart';
import '../../shared/workbook_fields.dart';
import '../../shared/segmented.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import '../views/view_providers.dart';
import 'calc_editor.dart';
import 'reference_picker.dart';

/// Barre d'édition : remplit la cellule sélectionnée avec l'éditeur adapté au
/// type de sa colonne.
class EditBar extends ConsumerStatefulWidget {
  const EditBar({super.key});

  @override
  ConsumerState<EditBar> createState() => _EditBarState();
}

class _EditBarState extends ConsumerState<EditBar> {
  final _controller = TextEditingController();
  final _categoryController = TextEditingController();
  final _focusNode = FocusNode();
  final _categoryFocus = FocusNode();
  CellInputError? _error;

  /// Le texte de la cellule tel qu'il a été chargé dans le champ : s'il n'a
  /// pas changé, aucune saisie n'est en cours.
  String _loaded = '';

  @override
  void initState() {
    super.initState();
    WorkbookFields.register(
      _focusNode,
      pending: () => _controller.text != _loaded,
    );
    WorkbookFields.register(
      _categoryFocus,
      pending: () => _categoryController.text.isNotEmpty,
    );
  }

  @override
  void dispose() {
    WorkbookFields.unregister(_focusNode);
    WorkbookFields.unregister(_categoryFocus);
    _controller.dispose();
    _categoryController.dispose();
    _focusNode.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  /// Aligne le champ sur la cellule quand la sélection ou sa valeur change.
  void _sync(SelectedCell? cell) {
    final text = cell == null ? '' : cellInputText(cell.row[cell.column.id]);
    _loaded = text;
    if (_controller.text != text) _controller.text = text;
    if (_error != null) setState(() => _error = null);
  }

  /// Valide la saisie. Si elle est acceptée, la sélection passe à la ligne
  /// affichée suivante et le champ garde le focus, pour enchaîner les saisies
  /// comme dans un tableur. Si elle est refusée, le texte reste à corriger.
  Future<void> _submit(SelectedCell cell) async {
    final error = await ref
        .read(workbookServiceProvider)
        .enterText(cell.row, cell.column, _controller.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      final rows = ref.read(visibleRowsProvider(cell.row.sheetId));
      final index = rows.indexWhere((row) => row.id == cell.row.id);
      if (index >= 0 && index + 1 < rows.length) {
        ref
            .read(selectionProvider.notifier)
            .select(rows[index + 1].id, cell.column.id);
        _startEditing();
        return;
      }
    }
    _focusNode.requestFocus();
  }

  /// Donne la saisie à l'éditeur de la cellule sélectionnée, une fois la
  /// barre reconstruite pour elle. Le texte est sélectionné en entier :
  /// taper remplace la valeur, comme dans un tableur.
  ///
  /// Un booléen ou une référence n'ont pas de champ de saisie : rien ne se
  /// passe. Les formules et les cases de calcul ont leur propre champ, qui
  /// suit [editRequestProvider] de son côté.
  void _startEditing() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Le champ à viser dépend du type de la colonne affichée maintenant,
      // pas des champs qui ont existé pour la cellule précédente.
      switch (ref.read(selectedCellProvider)?.column.type) {
        case ColumnType.text:
        case ColumnType.number:
        case ColumnType.percent:
        case ColumnType.date:
        case ColumnType.duration:
          _focusNode.requestFocus();
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        case ColumnType.singleCategory:
        case ColumnType.multiCategory:
          _categoryFocus.requestFocus();
        case ColumnType.boolean:
        case ColumnType.reference:
        case ColumnType.formula:
        case null:
          break;
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedCellProvider, (_, next) => _sync(next));
    ref.listen(editRequestProvider, (_, _) => _startEditing());
    final cell = ref.watch(selectedCellProvider);
    final selection = ref.watch(selectionProvider);
    final column = ref.watch(selectedColumnProvider);
    final calcColumn = ref.watch(calcColumnProvider);

    final Widget content;
    if (calcColumn != null && selection != null) {
      // Une case de calcul : en bas de la grille, ou sur une ligne de groupe.
      final bottom = selection is CalcCellSelected;
      content = _Line(
        reference: bottom
            ? 'Calcul ${selection.index + 1} · ${calcColumn.label}'
            : 'Calcul de groupe · ${calcColumn.label}',
        icon: AppIcons.formula,
        type: bottom ? 'Case de calcul' : 'Opération de groupe',
        child: CalcEditor(column: calcColumn, selection: selection),
      );
    } else if (selection is ColumnSelected &&
        column != null &&
        column.type == ColumnType.formula) {
      // Une colonne Formule a une seule formule pour toutes ses lignes.
      content = _Line(
        reference: columnTitle(column),
        icon: column.type.icon,
        type: column.type.label,
        child: FormulaEditor(column: column),
      );
    } else if (selection is ColumnSelected && column != null) {
      content = _Line(
        reference: columnTitle(column),
        icon: column.type.icon,
        type: column.type.label,
        child: const Text(
          'Colonne entière sélectionnée : les réglages de la barre de '
          'style s\'appliquent à toutes ses cellules.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSubtle,
          ),
        ),
      );
    } else if (cell == null) {
      content = const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Sélectionnez une cellule pour la modifier.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Même hauteur d'un type de colonne à l'autre : la grille ne bouge
          // pas quand on change de cellule. Seule une longue liste de
          // catégories, qui passe à la ligne, agrandit la barre.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _editorHeight),
            child: _Line(
              reference: '${cell.column.letter}${cell.row.position + 1}',
              icon: cell.column.type.icon,
              type: cell.column.type.label,
              trailing: cell.column.type == ColumnType.formula
                  // Une cellule calculée ne se vide pas.
                  ? null
                  : IconBtn(
                      tooltip: 'Vider la cellule',
                      icon: AppIcons.close,
                      onPressed: () => ref
                          .read(workbookServiceProvider)
                          .setValue(cell.row, cell.column, null),
                    ),
              child: _editor(cell),
            ),
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const AppIcon(
                      AppIcons.error,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _message(error),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      // + 1 pour la bordure : la barre a la même hauteur vide ou remplie.
      // 32 px de champ, 8 px de marge en haut et en bas, 1 px de bordure.
      constraints: const BoxConstraints(minHeight: AppSizes.barHeight + 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.headerLine)),
      ),
      alignment: Alignment.centerLeft,
      child: content,
    );
  }

  static const double _editorHeight = 32;

  Widget _editor(SelectedCell cell) {
    final service = ref.read(workbookServiceProvider);
    final value = cell.row[cell.column.id];
    switch (cell.column.type) {
      case ColumnType.formula:
        return FormulaEditor(column: cell.column);

      case ColumnType.boolean:
        return Align(
          alignment: Alignment.centerLeft,
          child: Segmented<bool>(
            selected: value is BoolValue && value.value,
            onSelected: (next) =>
                service.setValue(cell.row, cell.column, BoolValue(next)),
            padding: 14,
            minSegmentWidth: 64,
            options: const [
              (value: true, label: 'Vrai', icon: null),
              (value: false, label: 'Faux', icon: null),
            ],
          ),
        );

      case ColumnType.reference:
        return ReferencePicker(row: cell.row, column: cell.column);

      case ColumnType.singleCategory:
      case ColumnType.multiCategory:
        return _categories(cell, value);

      case ColumnType.number:
      case ColumnType.percent:
        final number = value is NumberValue ? value.number : 0.0;
        return Row(
          children: [
            IconBtn(
              tooltip: 'Diminuer de 1',
              icon: AppIcons.minus,
              iconSize: 14,
              bordered: true,
              onPressed: () => service.setValue(
                cell.row,
                cell.column,
                NumberValue(number - 1),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(width: 180, child: _textField(cell)),
            if (cell.column.type == ColumnType.percent) ...[
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(left: 2, right: 4),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSubtle,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            IconBtn(
              tooltip: 'Augmenter de 1',
              icon: AppIcons.plus,
              iconSize: 14,
              bordered: true,
              onPressed: () => service.setValue(
                cell.row,
                cell.column,
                NumberValue(number + 1),
              ),
            ),
          ],
        );

      case ColumnType.date:
        return Row(
          children: [
            SizedBox(
              width: 180,
              child: _textField(
                cell,
                // Le bouton du calendrier est dans le champ, comme celui
                // d'un champ date de navigateur.
                suffix: IconBtn(
                  tooltip: 'Choisir une date',
                  icon: AppIcons.calendar,
                  iconSize: 14,
                  size: 28,
                  onPressed: () => _pickDate(cell, value),
                ),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, _editorHeight),
              ),
              onPressed: () => service.setValue(
                cell.row,
                cell.column,
                DateValue.fromDateTime(DateTime.now()),
              ),
              child: const Text('Aujourd\'hui'),
            ),
          ],
        );

      case ColumnType.duration:
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 180, child: _textField(cell)),
        );

      case ColumnType.text:
        return _textField(cell);
    }
  }

  Future<void> _pickDate(SelectedCell cell, CellValue? value) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value is DateValue ? value.date : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      await ref
          .read(workbookServiceProvider)
          .setValue(cell.row, cell.column, DateValue.fromDateTime(picked));
    }
  }

  Widget _textField(SelectedCell cell, {Widget? suffix}) {
    final type = cell.column.type;
    final alignRight = defaultAlignment(type) == TextAlignment.right;
    return SizedBox(
      height: _editorHeight,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(fontSize: 13),
        textAlignVertical: TextAlignVertical.center,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        decoration: InputDecoration(
          hintText: _hint(type),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          enabledBorder: _error == null
              ? null
              : fieldBorder(color: AppColors.danger),
          focusedBorder: _error == null
              ? null
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppColors.danger,
                    width: 2,
                  ),
                ),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 32),
        ),
        onSubmitted: (_) => _submit(cell),
      ),
    );
  }

  /// Catégories proposées en pastilles, plus un champ pour en créer une.
  Widget _categories(SelectedCell cell, CellValue? value) {
    final service = ref.read(workbookServiceProvider);
    final rows = ref.watch(rowsProvider(cell.row.sheetId)).value ?? const [];
    final all = categoriesOf(cell.column, rows);
    final current = value is CategoryValue
        ? value.categories
        : const <String>[];

    Future<void> add() async {
      final name = _categoryController.text.trim();
      if (name.isEmpty) return;
      _categoryController.clear();
      if (current.contains(name)) return;
      await service.toggleCellCategory(cell.row, cell.column, name);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (all.isEmpty)
          const Text(
            'Aucune catégorie dans cette colonne pour l\'instant.',
            style: AppText.help,
          ),
        for (final category in all)
          _CategoryToggle(
            key: Key('category-$category'),
            label: category,
            selected: current.contains(category),
            onTap: () =>
                service.toggleCellCategory(cell.row, cell.column, category),
          ),
        SizedBox(
          width: 170,
          height: 28,
          child: TextField(
            controller: _categoryController,
            focusNode: _categoryFocus,
            style: const TextStyle(fontSize: 13),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Nouvelle catégorie',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              enabledBorder: _pill(AppColors.fieldBorder),
              border: _pill(AppColors.fieldBorder),
              focusedBorder: _pill(AppColors.accent, width: 2),
            ),
            onSubmitted: (_) => add(),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 8, right: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: add,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(AppIcons.plus, size: 14, color: AppColors.accent),
              SizedBox(width: 6),
              Text('Ajouter'),
            ],
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _pill(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  static String _hint(ColumnType type) => switch (type) {
    ColumnType.text => 'Saisir un texte',
    ColumnType.number || ColumnType.percent => '0',
    ColumnType.date => 'JJ/MM/AAAA',
    ColumnType.duration => '1:30 ou 45 min',
    _ => '',
  };

  static String _message(CellInputError error) => switch (error) {
    CellInputError.notANumber => 'Saisissez un nombre, par exemple 12,5.',
    CellInputError.notADate => 'Saisissez une date, par exemple 04/12/2026.',
    CellInputError.notADuration =>
      'Saisissez une durée, par exemple 1:30 ou 45 min.',
    CellInputError.notABoolean => 'Saisissez vrai ou faux.',
    CellInputError.notTypable => 'Ce type ne se saisit pas au clavier.',
  };
}

class _Reference extends StatelessWidget {
  const _Reference(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('edit-reference'),
      constraints: const BoxConstraints(minWidth: 56),
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

/// Une ligne de la barre d'édition : référence, type, trait, éditeur et
/// action éventuelle à droite, espacés de 10 px comme dans la maquette.
class _Line extends StatelessWidget {
  const _Line({
    required this.reference,
    required this.icon,
    required this.type,
    required this.child,
    this.trailing,
  });

  final String reference;
  final AppIconData icon;
  final String type;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Reference(reference),
        const SizedBox(width: 10),
        AppIcon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          type,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        const VSeparator(),
        const SizedBox(width: 10),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
        if (trailing case final action?) ...[const SizedBox(width: 10), action],
      ],
    );
  }
}

class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.text;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accentTint : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.fieldBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: AppSizes.smallControl,
            padding: EdgeInsets.only(left: selected ? 8 : 12, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  AppIcon(AppIcons.check, size: 14, color: color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
