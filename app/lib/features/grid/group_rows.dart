import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/providers.dart';
import '../formulas/formula_text.dart';
import '../views/view_providers.dart';
import 'calc_cell_view.dart';
import 'grid_providers.dart';

/// Nom affiché d'un groupe : sa catégorie, le libellé de la ligne
/// référencée, ou « Sans statut » pour les lignes sans valeur.
String groupName(WidgetRef ref, ColumnDef column, RowGroup group) {
  if (group.category case final category?) return category;
  if (group.reference case final id?) {
    final target = column.reference?.targetSheetId;
    final labels = target == null
        ? const <RowId, String>{}
        : ref.watch(rowLabelsProvider(target));
    return labels[id] ?? 'Ligne supprimée';
  }
  final name = column.name.trim();
  return name.isEmpty ? 'Sans valeur' : 'Sans ${name.toLowerCase()}';
}

/// Ligne d'en-tête d'un groupe.
///
/// À gauche, sur la largeur de la première colonne, le libellé du groupe :
/// un clic le replie ou le déplie. Sous chaque autre colonne, une case
/// d'opération : son contenu vaut pour tous les groupes, et chaque groupe
/// l'évalue sur ses propres lignes.
class GroupHeader extends ConsumerWidget {
  const GroupHeader({
    super.key,
    required this.column,
    required this.group,
    required this.columns,
    required this.widthOf,
    required this.first,
  });

  static const double height = 36;

  /// Espace au-dessus d'un groupe, pour le détacher du précédent.
  static const double gap = 14;

  /// La colonne de regroupement.
  final ColumnDef column;
  final RowGroup group;

  /// Les colonnes affichées.
  final List<ColumnDef> columns;
  final double Function(ColumnDef column) widthOf;
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = groupName(ref, column, group);
    final count = group.rows.length;
    final countText = count == 0
        ? 'Aucune ligne'
        : '$count ${count > 1 ? 'lignes' : 'ligne'}';
    final collapsed = ref.watch(
      collapsedGroupsProvider.select(
        (ids) => ids.contains(CollapsedGroups.idOf(column, group)),
      ),
    );
    final formulas = ref.watch(sheetFormulasProvider(column.sheetId));
    final selection = ref.watch(selectionProvider);
    final labelWidth =
        AppSizes.rowHeaderWidth +
        (columns.isEmpty ? 0 : widthOf(columns.first));

    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : gap),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.header,
          border: Border(bottom: BorderSide(color: AppColors.headerLine)),
        ),
        // Le trait du haut est dessiné par-dessus, sans prendre de place.
        foregroundDecoration: first
            ? null
            : const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.headerLine)),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: labelWidth,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.headerLine)),
              ),
              child: Semantics(
                button: true,
                expanded: !collapsed,
                label: 'Groupe $name, $countText',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => ref
                      .read(collapsedGroupsProvider.notifier)
                      .toggle(column, group),
                  // Comme dans la maquette, ce qui dépasse la largeur de la
                  // première colonne est coupé.
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18, right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              AppIcons.chevronDown,
                              size: 10,
                              color: AppColors.text,
                              turns: collapsed ? 3 : 0,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              column.label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (group.isNone)
                              Text(
                                name,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSubtle,
                                ),
                              )
                            else
                              _GroupChip(name),
                            const SizedBox(width: 8),
                            Text(
                              countText,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final other in columns.skip(1))
              CalcCellView(
                label: 'Opération du groupe $name, colonne ${other.label}',
                display: calcDisplay(
                  formulas.calcCell(other.groupCalc, rows: group.rows),
                ),
                width: widthOf(other),
                height: height - 1,
                background: AppColors.header,
                bottomLine: false,
                selected:
                    selection is GroupCalcSelected &&
                    selection.columnId == other.id &&
                    selection.groupKey == group.key,
                onTap: () => ref
                    .read(selectionProvider.notifier)
                    .selectGroupCalc(other.id, group.key, edit: true),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pied d'un groupe : ajoute une ligne déjà rangée dans ce groupe.
class GroupAddRow extends ConsumerWidget {
  const GroupAddRow({
    super.key,
    required this.sheet,
    required this.column,
    required this.group,
    required this.firstColumn,
  });

  static const double height = 30;

  final Sheet sheet;
  final ColumnDef column;
  final RowGroup group;

  /// La première colonne affichée : la cellule sélectionnée après l'ajout.
  final ColumnDef? firstColumn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = groupName(ref, column, group);
    // Toute la ligne est cliquable, pas seulement son libellé.
    return Semantics(
      button: true,
      label: 'Ajouter une ligne au groupe $name',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () async {
            final value = group.valueFor(column);
            if (value == null) return;
            final selection = ref.read(selectionProvider.notifier);
            final created = await ref.read(workbookServiceProvider).addRowWith(
              sheet.id,
              {column.id: value},
            );
            final target = firstColumn;
            if (target != null) {
              selection.select(created.id, target.id, edit: true);
            }
          },
          child: Container(
            height: height,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.gridLine)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AppIcons.plus, size: 12, color: AppColors.textMuted),
                SizedBox(width: 6),
                Text(
                  'Ajouter une ligne',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille du nom d'un groupe ; elle se tronque si la colonne est étroite.
class _GroupChip extends StatelessWidget {
  const _GroupChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }
}
