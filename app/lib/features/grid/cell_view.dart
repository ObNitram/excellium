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
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: inSelectedColumn
                ? AppColors.columnTint
                : (style.fillColor == null
                      ? AppColors.surface
                      : Color(style.fillColor!)),
            border: const Border(
              right: BorderSide(color: AppColors.gridLine),
              bottom: BorderSide(color: AppColors.gridLine),
            ),
          ),
          // Le cadre de la cellule sélectionnée et les bordures choisies sont
          // dessinés par-dessus, comme l'ombre intérieure de la maquette : le
          // texte ne bouge pas.
          foregroundDecoration: selected
              ? BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2),
                )
              : switch (style.border) {
                  CellBorder.none => null,
                  CellBorder.bottom => const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.text)),
                  ),
                  CellBorder.box => BoxDecoration(
                    border: Border.all(color: AppColors.text),
                  ),
                },
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
        fontFamily: switch (style.font) {
          CellFont.sans => AppFonts.sans,
          CellFont.serif => AppFonts.serif,
          CellFont.mono => AppFonts.mono,
        },
        fontSize: AppFonts.pixels(style.fontSize),
        // La couleur choisie l'emporte sur celle qu'impose la valeur (Faux
        // en gris, erreur en rouge reste rouge).
        color: style.textColor != null && color != AppColors.danger
            ? Color(style.textColor!)
            : color,
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
    // Avec le retour à la ligne, le texte occupe toute la hauteur de la
    // ligne ; ce qui dépasse est coupé.
    maxLines: style.wrap ? null : 1,
    softWrap: style.wrap,
    overflow: style.wrap ? TextOverflow.clip : TextOverflow.ellipsis,
    textAlign: switch (style.align) {
      TextAlignment.left => TextAlign.left,
      TextAlignment.center => TextAlign.center,
      TextAlignment.right => TextAlign.right,
    },
    style: _textStyle(style, color: color),
  );

  /// Un nombre de la cellule, avec les décimales et le symbole choisis.
  String _number(CellValue? value, ColumnType type, ResolvedStyle style) =>
      formatCell(
        value,
        type,
        decimals: style.decimals,
        currency:
            type != ColumnType.percent &&
            style.numberFormat == NumberDisplay.currency,
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
                  _number(value, column.type, style),
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
        return _text(_number(value, column.type, style), style);

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
        // Un résultat numérique suit les décimales et le symbole choisis ;
        // une date ou une durée garde sa présentation.
        final cell = formulaAsCell(values.values[row.id], values.unit);
        if (cell == null) return const SizedBox.shrink();
        return _text(
          cell.value is NumberValue
              ? _number(cell.value, cell.type, style)
              : formatCell(cell.value, cell.type),
          style,
        );

      case ColumnType.number:
        return _text(_number(value, column.type, style), style);

      case ColumnType.text:
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
        // Avec le retour à la ligne, les pastilles passent à la ligne ; ce
        // qui dépasse la hauteur de la ligne est coupé.
        child: style.wrap
            ? ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    alignment: switch (style.align) {
                      TextAlignment.left => WrapAlignment.start,
                      TextAlignment.center => WrapAlignment.center,
                      TextAlignment.right => WrapAlignment.end,
                    },
                    children: [for (final label in labels) CategoryChip(label)],
                  ),
                ),
              )
            : ClipRect(
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
