import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/drag_data.dart';
import '../../shared/providers.dart';
import '../grid/cell_format.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import '../views/view_providers.dart';

/// Affichage kanban : une colonne « catégorie unique » fournit les étapes, et
/// chaque ligne devient une carte dans l'étape de sa catégorie. Glisser une
/// carte vers une autre étape change la catégorie de la ligne.
class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({super.key, required this.sheet});

  final Sheet sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyColumn = ref.watch(layoutKeyColumnProvider(sheet.id));
    if (keyColumn == null) {
      return const LayoutNotice(
        'Aucune colonne de type « Catégorie unique » dans cette feuille. '
        'Donnez ce type à une colonne pour l\'utiliser comme étapes du kanban.',
      );
    }
    final allRows = ref.watch(rowsProvider(sheet.id)).value ?? const [];
    final rows = [
      for (final row in ref.watch(visibleRowsProvider(sheet.id)))
        if (!row.isEmpty) row,
    ];
    final columns = ref.watch(visibleColumnsProvider(sheet.id));
    final selection = ref.watch(selectionProvider);
    final service = ref.read(workbookServiceProvider);

    final steps = categoriesOf(keyColumn, allRows);
    String stepOf(SheetRow row) => switch (row[keyColumn.id]) {
      CategoryValue(:final categories) => categories.first,
      _ => '',
    };
    final hasUnassigned = allRows.any(
      (row) => !row.isEmpty && stepOf(row).isEmpty,
    );

    // Le titre d'une carte vient de la première colonne Texte affichée.
    final others = [
      for (final column in columns)
        if (column.id != keyColumn.id) column,
    ];
    ColumnDef? titleColumn;
    for (final column in others) {
      if (column.type == ColumnType.text) {
        titleColumn = column;
        break;
      }
    }
    titleColumn ??= others.isEmpty ? null : others.first;
    final fieldColumns = [
      for (final column in others)
        if (column.id != titleColumn?.id) column,
    ];

    void move(RowId rowId, String step) {
      for (final row in allRows) {
        if (row.id != rowId) continue;
        service.setValue(
          row,
          keyColumn,
          step.isEmpty ? null : CategoryValue.single(step),
        );
      }
    }

    void shift(int index, int delta) {
      final target = index + delta;
      if (target < 0 || target >= steps.length) return;
      final next = List<String>.of(steps);
      final moved = next.removeAt(index);
      next.insert(target, moved);
      service.reorderCategories(keyColumn, next);
    }

    return Container(
      color: AppColors.header,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, step) in [
              ...steps,
              if (hasUnassigned) '',
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _Lane(
                  name: step.isEmpty ? 'Sans étape' : step,
                  canMoveLeft: step.isNotEmpty && index > 0,
                  canMoveRight: step.isNotEmpty && index < steps.length - 1,
                  onMoveLeft: () => shift(index, -1),
                  onMoveRight: () => shift(index, 1),
                  onDrop: (rowId) => move(rowId, step),
                  cards: [
                    for (final row in rows)
                      if (stepOf(row) == step)
                        _Card(
                          row: row,
                          title: _title(row, titleColumn),
                          fields: _fields(ref, row, fieldColumns),
                          selected:
                              selection is CellSelected &&
                              selection.rowId == row.id,
                          onTap: titleColumn == null
                              ? null
                              : () => ref
                                    .read(selectionProvider.notifier)
                                    .select(row.id, titleColumn!.id),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _title(SheetRow row, ColumnDef? titleColumn) {
    final text = titleColumn == null
        ? ''
        : formatCell(row[titleColumn.id], titleColumn.type);
    return text.isEmpty ? 'Ligne ${row.position + 1}' : text;
  }

  /// Jusqu'à quatre autres valeurs de la ligne, précédées du nom de leur
  /// colonne quand elle en a un.
  static List<({IconData icon, String text})> _fields(
    WidgetRef ref,
    SheetRow row,
    List<ColumnDef> columns,
  ) {
    final fields = <({IconData icon, String text})>[];
    for (final column in columns) {
      if (fields.length >= 4) break;
      final value = row[column.id];
      if (value == null || (value is BoolValue && !value.value)) continue;
      var text = formatCell(value, column.type);
      if (value is ReferenceValue) {
        final target = column.reference?.targetSheetId;
        final labels = target == null
            ? const <RowId, String>{}
            : ref.watch(rowLabelsProvider(target));
        text = value.rowIds
            .map((id) => labels[id] ?? 'Ligne supprimée')
            .join(', ');
      }
      final name = column.name.trim();
      fields.add((
        icon: column.type.icon,
        text: name.isEmpty ? text : '$name : $text',
      ));
    }
    return fields;
  }
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.name,
    required this.cards,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onDrop,
  });

  final String name;
  final List<_Card> cards;
  final bool canMoveLeft;
  final bool canMoveRight;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final ValueChanged<RowId> onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<RowDrag>(
      onAcceptWithDetails: (details) => onDrop(details.data.id),
      builder: (context, candidates, _) => Container(
        width: 272,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? const Color(0xFFE6E9ED)
              : AppColors.accentTint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 2,
            color: candidates.isEmpty ? Colors.transparent : AppColors.accent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${cards.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                  ),
                ),
                if (canMoveLeft)
                  IconButton(
                    tooltip: 'Déplacer l\'étape $name vers la gauche',
                    iconSize: 14,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onMoveLeft,
                  ),
                if (canMoveRight)
                  IconButton(
                    tooltip: 'Déplacer l\'étape $name vers la droite',
                    iconSize: 14,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onMoveRight,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (cards.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Aucune carte',
                  style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
                ),
              ),
            for (final card in cards)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.row,
    required this.title,
    required this.fields,
    required this.selected,
    required this.onTap,
  });

  final SheetRow row;
  final String title;
  final List<({IconData icon, String text})> fields;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 252,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: selected ? 2 : 1,
          color: selected ? AppColors.accent : AppColors.headerLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          for (final field in fields)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(field.icon, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      field.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    return Draggable<RowDrag>(
      data: RowDrag(row.id),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: card,
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Carte $title',
        child: InkWell(onTap: onTap, child: card),
      ),
    );
  }
}

/// Message affiché à la place d'un affichage qui ne peut pas se construire.
class LayoutNotice extends StatelessWidget {
  const LayoutNotice(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.header,
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSubtle,
          ),
        ),
      ),
    );
  }
}
