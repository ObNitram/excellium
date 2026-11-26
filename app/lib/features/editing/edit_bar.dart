import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    _categoryController.dispose();
    _focusNode.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  /// Aligne le champ sur la cellule quand la sélection ou sa valeur change.
  void _sync(SelectedCell? cell) {
    final text = cell == null ? '' : cellInputText(cell.row[cell.column.id]);
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

    const typeStyle = TextStyle(fontSize: 13, color: AppColors.textMuted);
    final Widget content;
    if (calcColumn != null && selection != null) {
      // Une case de calcul : en bas de la grille, ou sur une ligne de groupe.
      final bottom = selection is CalcCellSelected;
      content = Row(
        children: [
          _Reference(
            bottom
                ? 'Calcul ${selection.index + 1} · ${calcColumn.label}'
                : 'Calcul de groupe · ${calcColumn.label}',
          ),
          const SizedBox(width: 10),
          const Icon(Icons.functions, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            bottom ? 'Case de calcul' : 'Opération de groupe',
            style: typeStyle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CalcEditor(column: calcColumn, selection: selection),
          ),
        ],
      );
    } else if (selection is ColumnSelected &&
        column != null &&
        column.type == ColumnType.formula) {
      // Une colonne Formule a une seule formule pour toutes ses lignes.
      content = Row(
        children: [
          _Reference(columnTitle(column)),
          const SizedBox(width: 10),
          Icon(column.type.icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(column.type.label, style: typeStyle),
          const SizedBox(width: 12),
          Expanded(child: FormulaEditor(column: column)),
        ],
      );
    } else if (selection is ColumnSelected && column != null) {
      content = Row(
        children: [
          _Reference(columnTitle(column)),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Colonne entière sélectionnée : les réglages de la barre de '
              'style s\'appliquent à toutes ses cellules.',
              style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
            ),
          ),
        ],
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
            child: Row(
              children: [
                _Reference('${cell.column.letter}${cell.row.position + 1}'),
                const SizedBox(width: 10),
                Icon(
                  cell.column.type.icon,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  cell.column.type.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _editor(cell)),
                // Une cellule calculée ne se vide pas.
                if (cell.column.type != ColumnType.formula)
                  IconButton(
                    tooltip: 'Vider la cellule',
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                    color: AppColors.textSubtle,
                    onPressed: () => ref
                        .read(workbookServiceProvider)
                        .setValue(cell.row, cell.column, null),
                  ),
              ],
            ),
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
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
      constraints: const BoxConstraints(minHeight: AppSizes.barHeight + 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.headerLine)),
      ),
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
            _Step(
              tooltip: 'Diminuer de 1',
              icon: Icons.remove,
              onTap: () => service.setValue(
                cell.row,
                cell.column,
                NumberValue(number - 1),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(width: 200, child: _textField(cell)),
            const SizedBox(width: 4),
            _Step(
              tooltip: 'Augmenter de 1',
              icon: Icons.add,
              onTap: () => service.setValue(
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
            SizedBox(width: 180, child: _textField(cell)),
            IconButton(
              tooltip: 'Choisir une date',
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value is DateValue ? value.date : DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2200),
                );
                if (picked != null) {
                  await service.setValue(
                    cell.row,
                    cell.column,
                    DateValue.fromDateTime(picked),
                  );
                }
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, _editorHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          child: SizedBox(width: 200, child: _textField(cell)),
        );

      case ColumnType.text:
        return _textField(cell);
    }
  }

  Widget _textField(SelectedCell cell) {
    final type = cell.column.type;
    final alignRight = defaultAlignment(type) == TextAlignment.right;
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(fontSize: 13),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        isDense: true,
        hintText: _hint(type),
        border: const OutlineInputBorder(),
        enabledBorder: _error == null
            ? null
            : const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.danger),
              ),
        focusedBorder: _error == null
            ? null
            : const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.danger, width: 2),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        suffixText: type == ColumnType.percent ? '%' : null,
      ),
      onSubmitted: (_) => _submit(cell),
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
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
          child: TextField(
            controller: _categoryController,
            focusNode: _categoryFocus,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Nouvelle catégorie',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onSubmitted: (_) => add(),
          ),
        ),
        TextButton.icon(
          onPressed: add,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Ajouter'),
        ),
      ],
    );
  }

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

class _Step extends StatelessWidget {
  const _Step({required this.tooltip, required this.icon, required this.onTap});

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.fieldBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: AppColors.textSubtle),
        ),
      ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentTint : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.fieldBorder,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 14, color: color),
                const SizedBox(width: 4),
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
    );
  }
}
