import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
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
      // 32 px de boutons, 6 px de marge en haut et en bas, 1 px de bordure :
      // la barre a la même hauteur vide ou remplie.
      constraints: const BoxConstraints(minHeight: AppSizes.control + 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.headerLine)),
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

    final groups = <Widget>[
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
                icon: AppIcons.percent,
              ),
              (
                value: PercentDisplay.bar,
                label: 'Barre de progression',
                icon: AppIcons.progressBar,
              ),
            ],
          ),
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
                icon: AppIcons.boolean,
              ),
              (
                value: BoolDisplay.toggle,
                label: 'Interrupteur',
                icon: AppIcons.toggle,
              ),
              (
                value: BoolDisplay.text,
                label: 'Vrai / Faux',
                icon: AppIcons.text,
              ),
            ],
          ),
        ),
      if (textStyle)
        _Buttons([
          IconBtn(
            tooltip: 'Gras',
            on: style.bold,
            onPressed: () => apply(CellStyle(bold: !style.bold)),
            child: const Text(
              'G',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          IconBtn(
            tooltip: 'Italique',
            on: style.italic,
            onPressed: () => apply(CellStyle(italic: !style.italic)),
            child: const Text(
              'I',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          IconBtn(
            tooltip: 'Souligné',
            on: style.underline,
            onPressed: () => apply(CellStyle(underline: !style.underline)),
            child: const Text(
              'S',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ]),
      _Buttons([
        IconBtn(
          tooltip: 'Aligner à gauche',
          icon: AppIcons.alignLeft,
          on: style.align == TextAlignment.left,
          onPressed: () => apply(const CellStyle(align: TextAlignment.left)),
        ),
        IconBtn(
          tooltip: 'Centrer',
          icon: AppIcons.alignCenter,
          on: style.align == TextAlignment.center,
          onPressed: () => apply(const CellStyle(align: TextAlignment.center)),
        ),
        IconBtn(
          tooltip: 'Aligner à droite',
          icon: AppIcons.alignRight,
          on: style.align == TextAlignment.right,
          onPressed: () => apply(const CellStyle(align: TextAlignment.right)),
        ),
      ]),
    ];

    // Les groupes sont séparés par un trait vertical, comme dans la maquette.
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) const VSeparator(),
          group,
        ],
      ],
    );
  }
}

/// Boutons d'un même groupe, espacés de 2 px.
class _Buttons extends StatelessWidget {
  const _Buttons(this.buttons);

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (index, button) in buttons.indexed) ...[
        if (index > 0) const SizedBox(width: 2),
        button,
      ],
    ],
  );
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
