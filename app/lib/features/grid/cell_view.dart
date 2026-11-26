import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import '../formulas/formula_text.dart';
import 'cell_format.dart';
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
        onTap: () =>
            ref.read(selectionProvider.notifier).select(row.id, column.id),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: inSelectedColumn ? AppColors.columnTint : AppColors.surface,
            border: selected
                ? Border.all(color: AppColors.accent, width: 2)
                : const Border(
                    right: BorderSide(color: AppColors.gridLine),
                    bottom: BorderSide(color: AppColors.gridLine),
                  ),
          ),
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
          return Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (value.number / 100).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: AppColors.headerLine,
                    color: AppColors.accent,
                    semanticsLabel: formatCell(value, column.type),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatCell(value, column.type),
                style: _textStyle(
                  style,
                  color: AppColors.textSubtle,
                ).copyWith(fontSize: 11),
              ),
            ],
          );
        }
        return _text(formatCell(value, column.type), style);

      case ColumnType.singleCategory:
      case ColumnType.multiCategory:
        if (value is! CategoryValue) return const SizedBox.shrink();
        return _chips(value.categories);

      case ColumnType.reference:
        if (value is! ReferenceValue) return const SizedBox.shrink();
        final target = column.reference?.targetSheetId;
        final labels = target == null
            ? const <RowId, String>{}
            : ref.watch(rowLabelsProvider(target));
        final ids = column.reference?.cardinality == Cardinality.many
            ? value.rowIds
            : value.rowIds.take(1);
        return _chips([for (final id in ids) labels[id] ?? 'Ligne supprimée']);

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

  /// Les pastilles qui dépassent la largeur de la cellule sont coupées, sans
  /// erreur de mise en page.
  Widget _chips(Iterable<String> labels) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final label in labels)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: CategoryChip(label),
          ),
      ],
    ),
  );

  Widget _boolean(WidgetRef ref, ResolvedStyle style, bool checked) {
    void toggle(bool next) {
      ref.read(selectionProvider.notifier).select(row.id, column.id);
      ref.read(workbookServiceProvider).setValue(row, column, BoolValue(next));
    }

    switch (style.boolDisplay) {
      case BoolDisplay.checkbox:
        return SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: checked,
            activeColor: AppColors.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (next) => toggle(next ?? false),
          ),
        );
      case BoolDisplay.toggle:
        return SizedBox(
          height: 20,
          child: FittedBox(
            child: Switch(
              value: checked,
              activeTrackColor: AppColors.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: toggle,
            ),
          ),
        );
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
class CategoryChip extends StatelessWidget {
  const CategoryChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
      ),
    );
  }
}
