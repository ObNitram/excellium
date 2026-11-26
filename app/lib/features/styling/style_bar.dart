import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import '../../shared/segmented.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';

/// Barre de style.
///
/// Elle règle le style de la sélection : toute la colonne si elle est
/// sélectionnée, sinon la cellule. Seules les options qui ont un sens pour le
/// type de la colonne sont affichées.
class StyleBar extends ConsumerWidget {
  const StyleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final column = ref.watch(selectedColumnProvider);
    final cell = ref.watch(selectedCellProvider);
    final selection = ref.watch(selectionProvider);

    return Container(
      // + 1 pour la bordure : la barre a la même hauteur vide ou remplie.
      constraints: const BoxConstraints(minHeight: AppSizes.barHeight + 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.gridLine)),
      ),
      alignment: Alignment.centerLeft,
      child: column == null || (selection is CellSelected && cell == null)
          ? const Text(
              'Sélectionnez une cellule ou une colonne pour régler son style.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            )
          : _Controls(column: column, row: cell?.row),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.column, required this.row});

  final ColumnDef column;

  /// La ligne de la cellule sélectionnée ; `null` si c'est toute la colonne.
  final SheetRow? row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(workbookServiceProvider);
    final style = resolveStyle(column, row);
    final type = column.type;
    void apply(CellStyle patch) {
      final target = row;
      if (target == null) {
        service.styleColumn(column, patch);
      } else {
        service.styleCell(target, column, patch);
      }
    }

    final textStyle =
        type.hasTextStyle ||
        (type == ColumnType.boolean && style.boolDisplay == BoolDisplay.text);

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Target(
          label: row == null
              ? columnTitle(column)
              : '${column.letter}${row!.position + 1}',
          wholeColumn: row == null,
        ),
        if (type == ColumnType.boolean)
          _Labelled(
            label: 'Affichage',
            child: Segmented<BoolDisplay>(
              selected: style.boolDisplay,
              onSelected: (value) => apply(CellStyle(boolDisplay: value)),
              options: const [
                (
                  value: BoolDisplay.checkbox,
                  label: 'Case à cocher',
                  icon: Icons.check_box_outlined,
                ),
                (
                  value: BoolDisplay.toggle,
                  label: 'Interrupteur',
                  icon: Icons.toggle_on_outlined,
                ),
                (
                  value: BoolDisplay.text,
                  label: 'Vrai / Faux',
                  icon: Icons.title,
                ),
              ],
            ),
          ),
        if (type == ColumnType.percent)
          _Labelled(
            label: 'Affichage',
            child: Segmented<PercentDisplay>(
              selected: style.percentDisplay,
              onSelected: (value) => apply(CellStyle(percentDisplay: value)),
              options: const [
                (
                  value: PercentDisplay.value,
                  label: 'Valeur',
                  icon: Icons.percent,
                ),
                (
                  value: PercentDisplay.bar,
                  label: 'Barre de progression',
                  icon: Icons.linear_scale,
                ),
              ],
            ),
          ),
        if (textStyle)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Toggle(
                tooltip: 'Gras',
                icon: Icons.format_bold,
                on: style.bold,
                onTap: () => apply(CellStyle(bold: !style.bold)),
              ),
              _Toggle(
                tooltip: 'Italique',
                icon: Icons.format_italic,
                on: style.italic,
                onTap: () => apply(CellStyle(italic: !style.italic)),
              ),
              _Toggle(
                tooltip: 'Souligné',
                icon: Icons.format_underlined,
                on: style.underline,
                onTap: () => apply(CellStyle(underline: !style.underline)),
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Toggle(
              tooltip: 'Aligner à gauche',
              icon: Icons.format_align_left,
              on: style.align == TextAlignment.left,
              onTap: () => apply(const CellStyle(align: TextAlignment.left)),
            ),
            _Toggle(
              tooltip: 'Centrer',
              icon: Icons.format_align_center,
              on: style.align == TextAlignment.center,
              onTap: () => apply(const CellStyle(align: TextAlignment.center)),
            ),
            _Toggle(
              tooltip: 'Aligner à droite',
              icon: Icons.format_align_right,
              on: style.align == TextAlignment.right,
              onTap: () => apply(const CellStyle(align: TextAlignment.right)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rappelle sur quoi porte le style : une cellule ou toute une colonne.
class _Target extends StatelessWidget {
  const _Target({required this.label, required this.wholeColumn});

  final String label;
  final bool wholeColumn;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: wholeColumn
          ? 'Le style s\'applique à toute la colonne'
          : 'Le style s\'applique à cette cellule',
      child: Container(
        key: const Key('style-target'),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.accentTint,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              wholeColumn ? Icons.view_column_outlined : Icons.crop_din,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.tooltip,
    required this.icon,
    required this.on,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: on,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: on ? AppColors.accentTint : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: on ? AppColors.accent : AppColors.textSubtle,
            ),
          ),
        ),
      ),
    );
  }
}
