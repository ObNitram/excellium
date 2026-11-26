import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/providers.dart';
import '../formulas/formula_text.dart';
import 'cell_format.dart';
import 'column_type_ui.dart';
import 'grid_providers.dart';

/// Une cellule de la grille, rendue selon le type et le style de sa colonne.
class CellView extends ConsumerWidget {
  const CellView({
    super.key,
    required this.row,
    required this.column,
    required this.width,
    required this.height,
    required this.selected,
    required this.inSelectedColumn,
  });

  final SheetRow row;
  final ColumnDef column;
  final double width;
  final double height;

  /// Vrai quand cette cellule est la cellule sélectionnée.
  final bool selected;

  /// Vrai quand toute la colonne est sélectionnée.
  final bool inSelectedColumn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = resolveStyle(column, row);
    return Semantics(
      label: 'Cellule ${column.letter}${row.position + 1}',
      selected: selected,
      child: InkWell(
        // Un clic sélectionne la cellule et ouvre la saisie : on tape tout
        // de suite, sans passer par la barre d'édition.
        onTap: () => ref
            .read(selectionProvider.notifier)
            .select(row.id, column.id, edit: true),
        child: Container(
          width: width,
          height: height,
          padding: _padding,
          decoration: BoxDecoration(
            color: inSelectedColumn ? AppColors.columnTint : AppColors.surface,
            border: const Border(
              right: BorderSide(color: AppColors.gridLine),
              bottom: BorderSide(color: AppColors.gridLine),
            ),
          ),
          // Le cadre de la cellule sélectionnée est dessiné par-dessus, comme
          // l'ombre intérieure de la maquette : le texte ne bouge pas.
          foregroundDecoration: selected
              ? BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2),
                )
              : null,
          alignment: switch (style.align) {
            TextAlignment.left => Alignment.centerLeft,
            TextAlignment.center => Alignment.center,
            TextAlignment.right => Alignment.centerRight,
          },
          child: _content(ref, style),
        ),
      ),
    );
  }

  /// 7 px de marge, 4 et 5 px pour les pastilles des catégories.
  EdgeInsets get _padding =>
      column.type.isCategory || column.type == ColumnType.reference
      ? const EdgeInsets.only(left: 4, right: 5)
      : const EdgeInsets.symmetric(horizontal: 7);

  TextStyle _textStyle(ResolvedStyle style, {Color color = AppColors.text}) =>
      TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: style.bold ? FontWeight.w600 : FontWeight.w400,
        fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
        decoration: style.underline ? TextDecoration.underline : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  Widget _text(
    String text,
    ResolvedStyle style, {
    Color color = AppColors.text,
  }) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: _textStyle(style, color: color),
  );

  Widget _content(WidgetRef ref, ResolvedStyle style) {
    final value = row[column.id];
    switch (column.type) {
      case ColumnType.boolean:
        return _boolean(ref, style, value is BoolValue && value.value);

      case ColumnType.percent:
        if (value is NumberValue &&
            style.percentDisplay == PercentDisplay.bar) {
          final ratio = (value.number / 100).clamp(0, 1).toDouble();
          return Row(
            children: [
              Expanded(
                child: Container(
                  key: const Key('percent-bar'),
                  height: 8,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: AppColors.headerLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    heightFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 32),
                child: Text(
                  formatCell(value, column.type),
                  textAlign: TextAlign.right,
                  style: _textStyle(
                    style,
                    color: AppColors.textSubtle,
                  ).copyWith(fontSize: 11),
                ),
              ),
            ],
          );
        }
        return _text(formatCell(value, column.type), style);

      case ColumnType.singleCategory:
      case ColumnType.multiCategory:
        return _chips(
          value is CategoryValue ? value.categories : const [],
          style,
        );

      case ColumnType.reference:
        if (value is! ReferenceValue) return _chips(const [], style);
        final target = column.reference?.targetSheetId;
        final labels = target == null
            ? const <RowId, String>{}
            : ref.watch(rowLabelsProvider(target));
        final ids = column.reference?.cardinality == Cardinality.many
            ? value.rowIds
            : value.rowIds.take(1);
        return _chips([
          for (final id in ids) labels[id] ?? 'Ligne supprimée',
        ], style);

      case ColumnType.formula:
        // Valeur calculée ; une ligne vide n'en a pas.
        final computed = ref.watch(sheetFormulasProvider(row.sheetId));
        final values = computed.column(column.id);
        if (values.hasError) {
          return row.isEmpty
              ? const SizedBox.shrink()
              : _text(formulaErrorMark, style, color: AppColors.danger);
        }
        final number = values.values[row.id];
        return number == null
            ? const SizedBox.shrink()
            : _text(formulaValueText(number, values.unit), style);

      case ColumnType.text:
      case ColumnType.number:
      case ColumnType.date:
      case ColumnType.duration:
        return _text(formatCell(value, column.type), style);
    }
  }

  /// Les pastilles, suivies de la petite flèche des cellules à choix, comme
  /// dans la maquette. Celles qui dépassent la largeur de la cellule sont
  /// coupées, sans erreur de mise en page.
  Widget _chips(Iterable<String> labels, ResolvedStyle style) => Row(
    children: [
      Expanded(
        child: ClipRect(
          child: Align(
            alignment: switch (style.align) {
              TextAlignment.left => Alignment.centerLeft,
              TextAlignment.center => Alignment.center,
              TextAlignment.right => Alignment.centerRight,
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, label) in labels.indexed) ...[
                    if (index > 0) const SizedBox(width: 3),
                    CategoryChip(label),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      const AppIcon(
        AppIcons.chevronDown,
        size: 10,
        color: AppColors.fieldBorder,
      ),
    ],
  );

  Widget _boolean(WidgetRef ref, ResolvedStyle style, bool checked) {
    void toggle(bool next) {
      ref.read(selectionProvider.notifier).select(row.id, column.id);
      ref.read(workbookServiceProvider).setValue(row, column, BoolValue(next));
    }

    switch (style.boolDisplay) {
      case BoolDisplay.checkbox:
        return AppCheckbox(value: checked, onChanged: toggle);
      case BoolDisplay.toggle:
        return AppSwitch(value: checked, onChanged: toggle);
      case BoolDisplay.text:
        return InkWell(
          onTap: () => toggle(!checked),
          child: _text(
            checked ? 'Vrai' : 'Faux',
            style,
            color: checked ? AppColors.text : AppColors.textMuted,
          ),
        );
    }
  }
}

/// Pastille d'une catégorie ou d'une ligne référencée.
typedef CategoryChip = CategoryPill;
