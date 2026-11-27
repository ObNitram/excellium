import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../columns/column_menu.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import '../workbook/workbook_providers.dart';

/// Choix des lignes référencées par une cellule de type Référence.
///
/// La loupe règle les colonnes de la feuille liée dans lesquelles on cherche ;
/// le bouton de recherche ouvre le champ et la liste des lignes trouvées.
class ReferencePicker extends ConsumerWidget {
  const ReferencePicker({super.key, required this.row, required this.column});

  final SheetRow row;
  final ColumnDef column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = column.reference ?? const ReferenceConfig();
    final target = config.targetSheetId;
    final sheets = ref.watch(sheetsProvider).value ?? const [];
    Sheet? targetSheet;
    for (final sheet in sheets) {
      if (sheet.id == target) targetSheet = sheet;
    }

    final relation = Popover(
      width: 280,
      anchorBuilder: (context, toggle, _) => TextButton(
        onPressed: toggle,
        child: const Text('Paramétrer la relation'),
      ),
      panelBuilder: (context, close) => ReferenceConfigEditor(column: column),
    );

    if (target == null || targetSheet == null) {
      return Row(
        children: [
          const Flexible(
            child: Text(
              'Aucune feuille liée pour cette colonne.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          relation,
        ],
      );
    }

    final labels = ref.watch(rowLabelsProvider(target));
    final value = row[column.id];
    final many = config.cardinality == Cardinality.many;
    final current = value is ReferenceValue
        ? (many ? value.rowIds : value.rowIds.take(1).toList())
        : const <RowId>[];
    final summary = current.isEmpty
        ? 'Aucune référence'
        : current.map((id) => labels[id] ?? 'Ligne supprimée').join(', ');

    // Comme dans la maquette : un seul champ, avec à gauche la loupe qui
    // règle les colonnes de recherche. Cliquer dans le champ ouvre la liste
    // des lignes, où l'on tape la recherche.
    return Row(
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, minWidth: 240),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.fieldBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Popover(
                    width: 300,
                    anchorBuilder: (context, toggle, _) => Tooltip(
                      message: 'Paramétrer la recherche',
                      child: InkWell(
                        onTap: toggle,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(5),
                        ),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.only(left: 8, right: 6),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: AppColors.headerLine),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(AppIcons.search),
                              SizedBox(width: 4),
                              AppIcon(AppIcons.chevronDown, size: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    panelBuilder: (context, close) =>
                        _SearchColumns(column: column, target: targetSheet!),
                  ),
                  Expanded(
                    child: Popover(
                      width: 420,
                      anchorBuilder: (context, toggle, _) => Semantics(
                        button: true,
                        child: InkWell(
                          onTap: toggle,
                          hoverColor: Colors.transparent,
                          mouseCursor: SystemMouseCursors.text,
                          child: Container(
                            height: 30,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Rechercher dans ${targetSheet!.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      panelBuilder: (context, close) =>
                          _Results(row: row, column: column, close: close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSubtle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        relation,
      ],
    );
  }
}

/// Colonnes de la feuille liée prises en compte par la recherche.
class _SearchColumns extends ConsumerWidget {
  const _SearchColumns({required this.column, required this.target});

  final ColumnDef column;
  final Sheet target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = column.reference ?? const ReferenceConfig();
    final targetColumns =
        ref.watch(columnsProvider(target.id)).value ?? const [];
    // Sans réglage, la recherche porte sur la première colonne.
    final searched = config.searchColumnIds.isEmpty && targetColumns.isNotEmpty
        ? [targetColumns.first.id]
        : config.searchColumnIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PanelTitle('Rechercher dans'),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: Text(
            'Colonnes de « ${target.name} » prises en compte par la recherche.',
            style: AppText.help,
          ),
        ),
        for (final candidate in targetColumns)
          CheckRow(
            checked: searched.contains(candidate.id),
            icon: candidate.type.icon,
            label: columnTitle(candidate),
            detail: candidate.type.label,
            onChanged: (_) => _toggle(ref, config, searched, candidate.id),
          ),
      ],
    );
  }

  void _toggle(
    WidgetRef ref,
    ReferenceConfig config,
    List<ColumnId> searched,
    ColumnId id,
  ) {
    final next = searched.contains(id)
        ? [
            for (final other in searched)
              if (other != id) other,
          ]
        : [...searched, id];
    // Il reste toujours au moins une colonne de recherche.
    if (next.isEmpty) return;
    ref
        .read(workbookServiceProvider)
        .configureReference(column, config.copyWith(searchColumnIds: next));
  }
}

/// Champ de recherche et lignes trouvées dans la feuille liée.
class _Results extends ConsumerStatefulWidget {
  const _Results({
    required this.row,
    required this.column,
    required this.close,
  });

  final SheetRow row;
  final ColumnDef column;
  final VoidCallback close;

  @override
  ConsumerState<_Results> createState() => _ResultsState();
}

class _ResultsState extends ConsumerState<_Results> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final column = widget.column;
    final config = column.reference ?? const ReferenceConfig();
    final target = config.targetSheetId!;
    final targetColumns = ref.watch(columnsProvider(target)).value ?? const [];
    final targetRows = ref.watch(rowsProvider(target)).value ?? const [];
    // La ligne est relue à chaque construction pour refléter les choix faits
    // pendant que le panneau est ouvert.
    final rows = ref.watch(rowsProvider(column.sheetId)).value ?? const [];
    var row = widget.row;
    for (final candidate in rows) {
      if (candidate.id == row.id) row = candidate;
    }
    final value = row[column.id];
    final current = value is ReferenceValue ? value.rowIds : const <RowId>[];
    final many = config.cardinality == Cardinality.many;

    final found = searchRows(
      targetRows,
      targetColumns,
      searchColumnIds: config.searchColumnIds,
      query: _query,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            height: 32,
            child: TextField(
              autofocus: true,
              onChanged: (text) => setState(() => _query = text),
              style: const TextStyle(fontSize: 13),
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                prefixIcon: AppIcon(AppIcons.search),
                prefixIconConstraints: BoxConstraints(minWidth: 32),
                hintText: 'Rechercher une ligne',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
            ),
          ),
        ),
        if (found.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              _query.trim().isEmpty
                  ? 'Aucune ligne à référencer dans la feuille liée pour '
                        'l\'instant.'
                  : 'Aucun résultat pour « ${_query.trim()} ».',
              style: AppText.help,
            ),
          ),
        for (final candidate in found)
          PanelItem(
            label: rowLabel(candidate, targetColumns),
            selected: current.contains(candidate.id),
            onTap: () async {
              await ref
                  .read(workbookServiceProvider)
                  .setValue(
                    row,
                    column,
                    toggleReference(
                      value,
                      candidate.id,
                      cardinality: config.cardinality,
                    ),
                  );
              if (!many) widget.close();
            },
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSubtle,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: widget.close,
              child: const Text('Fermer'),
            ),
          ),
        ),
      ],
    );
  }
}
