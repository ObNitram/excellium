import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/pixel_lines.dart';
import '../../shared/popover.dart';
import '../../shared/drag_data.dart';
import '../../shared/providers.dart';
import '../grid/cell_format.dart';
import '../grid/grid_providers.dart';
import '../kanban/kanban_board.dart' show LayoutNotice;
import '../views/view_providers.dart';

/// Le mois affiché par le calendrier d'une feuille (son premier jour).
final calendarMonthProvider =
    NotifierProvider.family<CalendarMonth, DateTime, SheetId>(
      CalendarMonth.new,
    );

class CalendarMonth extends Notifier<DateTime> {
  CalendarMonth(this.sheetId);

  final SheetId sheetId;

  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void shift(int months) => state = DateTime(state.year, state.month + months);

  void show(DateTime date) => state = DateTime(date.year, date.month);
}

const _months = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

/// Affichage calendrier : chaque ligne est placée sur le jour de sa colonne
/// Date. Glisser une ligne vers un autre jour change sa date.
class CalendarView extends ConsumerWidget {
  const CalendarView({super.key, required this.sheet});

  final Sheet sheet;

  /// Nombre maximal de lignes montrées par jour avant « + N autres » ; moins
  /// si la case est trop basse.
  static const int maxPerDay = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyColumn = ref.watch(layoutKeyColumnProvider(sheet.id));
    if (keyColumn == null) {
      return const LayoutNotice(
        'Aucune colonne de type « Date » dans cette feuille. Donnez ce type à '
        'une colonne pour placer les lignes sur le calendrier.',
      );
    }
    final month = ref.watch(calendarMonthProvider(sheet.id));
    final monthState = ref.read(calendarMonthProvider(sheet.id).notifier);
    final allRows = ref.watch(rowsProvider(sheet.id)).value ?? const [];
    final rows = [
      for (final row in ref.watch(visibleRowsProvider(sheet.id)))
        if (!row.isEmpty) row,
    ];
    final columns = ref.watch(visibleColumnsProvider(sheet.id));
    final selection = ref.watch(selectionProvider);
    final service = ref.read(workbookServiceProvider);

    ColumnDef? titleColumn;
    for (final column in columns) {
      if (column.id != keyColumn.id && column.type == ColumnType.text) {
        titleColumn = column;
        break;
      }
    }
    for (final column in columns) {
      if (titleColumn == null && column.id != keyColumn.id) {
        titleColumn = column;
      }
    }

    final byDay = <String, List<SheetRow>>{};
    var undated = 0;
    for (final row in rows) {
      final value = row[keyColumn.id];
      if (value is DateValue) {
        byDay.putIfAbsent(value.iso, () => []).add(row);
      } else {
        undated++;
      }
    }

    // La grille commence un lundi et couvre des semaines entières.
    final lead = (DateTime(month.year, month.month).weekday + 6) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    final today = DateValue.fromDateTime(DateTime.now()).iso;

    void move(RowId rowId, DateValue date) {
      for (final row in allRows) {
        if (row.id == rowId) service.setValue(row, keyColumn, date);
      }
    }

    return Container(
      color: AppColors.header,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBtn(
                tooltip: 'Mois précédent',
                icon: AppIcons.chevronLeft,
                iconSize: 10,
                size: 28,
                bordered: true,
                color: AppColors.text,
                onPressed: () => monthState.shift(-1),
              ),
              const SizedBox(width: 8),
              IconBtn(
                tooltip: 'Mois suivant',
                icon: AppIcons.chevronRight,
                iconSize: 10,
                size: 28,
                bordered: true,
                color: AppColors.text,
                onPressed: () => monthState.shift(1),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 150),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${_months[month.month - 1]} ${month.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BarButton(
                label: 'Aujourd\'hui',
                dropdown: false,
                onPressed: () => monthState.show(DateTime.now()),
              ),
              const Spacer(),
              if (undated > 0)
                Text(
                  '$undated ${undated > 1 ? 'lignes' : 'ligne'} sans date',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LinedBox(
            color: AppColors.header,
            edges: const [
              Edges(
                top: Line(AppColors.headerLine),
                left: Line(AppColors.headerLine),
              ),
            ],
            child: Row(
              children: [
                for (final (index, day) in _weekdays.indexed)
                  Expanded(
                    child: LinedBox(
                      // 1 point de plus en haut et en bas, pour les traits.
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                      edges: [
                        Edges(
                          // Traits clairs entre les jours, foncé au bord.
                          right: Line(
                            index == _weekdays.length - 1
                                ? AppColors.headerLine
                                : AppColors.gridLine,
                          ),
                          bottom: const Line(AppColors.headerLine),
                        ),
                      ],
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LinedBox(
              edges: const [Edges(left: Line(AppColors.headerLine))],
              child: Column(
                children: [
                  for (var week = 0; week < weeks; week++)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var weekday = 0; weekday < 7; weekday++)
                            Expanded(
                              child: _dayCell(
                                ref,
                                date: DateValue.fromDateTime(
                                  DateTime(
                                    month.year,
                                    month.month,
                                    1 - lead + week * 7 + weekday,
                                  ),
                                ),
                                month: month,
                                today: today,
                                byDay: byDay,
                                titleColumn: titleColumn,
                                selection: selection,
                                onDrop: move,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(
    WidgetRef ref, {
    required DateValue date,
    required DateTime month,
    required String today,
    required Map<String, List<SheetRow>> byDay,
    required ColumnDef? titleColumn,
    required GridSelection? selection,
    required void Function(RowId, DateValue) onDrop,
  }) {
    final inMonth = date.date.month == month.month;
    final isToday = date.iso == today;
    final rows = byDay[date.iso] ?? const <SheetRow>[];

    return DragTarget<RowDrag>(
      onAcceptWithDetails: (details) => onDrop(details.data.id, date),
      builder: (context, candidates, _) => LinedBox(
        padding: const EdgeInsets.all(6),
        color: candidates.isNotEmpty
            ? AppColors.accentTint12
            : (inMonth ? AppColors.surface : AppColors.header),
        // Cadre de dépôt par-dessus, sans décaler le contenu.
        edges: [headerEdges, if (candidates.isNotEmpty) selectionFrame],
        child: LayoutBuilder(
          builder: (context, box) {
            // Nombre de lignes qui tiennent sous le numéro du jour : il dépend
            // de la hauteur de la fenêtre et du nombre de semaines du mois.
            final slots = ((box.maxHeight - _dayNumberHeight) / _slotHeight)
                .floor()
                .clamp(0, maxPerDay);
            // S'il n'y a pas la place pour tout, le dernier emplacement sert
            // à annoncer le reste.
            final shown = rows.length <= slots
                ? rows.length
                : (slots - 1).clamp(0, rows.length);
            final extra = rows.length - shown;
            final more = '+ $extra ${extra > 1 ? 'autres' : 'autre'}';
            const moreStyle = TextStyle(
              fontSize: 11,
              color: AppColors.textSubtle,
            );

            return ClipRect(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: _dayNumberHeight,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.accent : null,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '${date.date.day}',
                            semanticsLabel: formatCell(date, ColumnType.date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isToday
                                  ? Colors.white
                                  : (inMonth
                                        ? AppColors.text
                                        : AppColors.textMuted),
                            ),
                          ),
                        ),
                        // Case trop basse pour la moindre ligne : le compte
                        // se met à côté du numéro.
                        if (extra > 0 && slots == 0) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              more,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: moreStyle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    for (final row in rows.take(shown))
                      Padding(
                        padding: const EdgeInsets.only(top: _eventGap),
                        child: _Event(
                          row: row,
                          title: _title(row, titleColumn),
                          selected:
                              selection is CellSelected &&
                              selection.rowId == row.id,
                          onTap: titleColumn == null
                              ? null
                              : () => ref
                                    .read(selectionProvider.notifier)
                                    .select(row.id, titleColumn.id),
                        ),
                      ),
                    if (extra > 0 && slots > 0)
                      Container(
                        height: _Event.height,
                        margin: const EdgeInsets.only(top: _eventGap),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        alignment: Alignment.centerLeft,
                        child: Text(more, maxLines: 1, style: moreStyle),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const double _dayNumberHeight = 22;
  static const double _eventGap = 4;
  static const double _slotHeight = _Event.height + _eventGap;

  static String _title(SheetRow row, ColumnDef? titleColumn) {
    final text = titleColumn == null
        ? ''
        : formatCell(row[titleColumn.id], titleColumn.type);
    return text.isEmpty ? 'Ligne ${row.position + 1}' : text;
  }
}

class _Event extends StatelessWidget {
  const _Event({
    required this.row,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final SheetRow row;
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  /// Hauteur fixe : le calendrier calcule combien de lignes tiennent par jour.
  /// 4 px de marge en haut et en bas, une ligne de 12 px × 1,3.
  static const double height = 24;

  @override
  Widget build(BuildContext context) {
    final label = Container(
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.accentTint18,
        borderRadius: BorderRadius.circular(4),
      ),
      foregroundDecoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(width: 2, color: AppColors.accent),
            )
          : null,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          height: 1.3,
          color: AppColors.text,
        ),
      ),
    );
    return Draggable<RowDrag>(
      data: RowDrag(row.id),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(width: 180, child: label),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: label),
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(onTap: onTap, child: label),
      ),
    );
  }
}
