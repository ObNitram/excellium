import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/popover.dart';
import '../grid/cell_format.dart';
import '../grid/grid_providers.dart';
import '../views/view_providers.dart';

/// Critère de filtre d'une colonne, adapté à son type.
class ColumnFilterEditor extends ConsumerWidget {
  const ColumnFilterEditor({super.key, required this.column});

  final ColumnDef column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetId = column.sheetId;
    final filter = ref.watch(
      viewSpecProvider(sheetId).select((s) => s.query.filters[column.id]),
    );
    final notifier = ref.read(viewSpecProvider(sheetId).notifier);
    void set(FilterSpec? next) => notifier.setFilter(
      column.id,
      next == null || !next.isActive ? null : next,
    );

    switch (column.type) {
      case ColumnType.text:
        return _Field(
          key: ValueKey('filter-text-${column.id.value}'),
          label: 'Contient',
          initial: filter is TextContains ? filter.query : '',
          onChanged: (text) => set(TextContains(text)),
        );

      case ColumnType.number:
      case ColumnType.percent:
      case ColumnType.formula:
        final range = filter is NumberRange ? filter : const NumberRange();
        return Row(
          children: [
            Expanded(
              child: _Field(
                key: ValueKey('filter-min-${column.id.value}'),
                label: 'Minimum',
                initial: range.min == null ? '' : formatNumber(range.min!),
                onChanged: (text) =>
                    set(NumberRange(min: _number(text), max: range.max)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _Field(
                key: ValueKey('filter-max-${column.id.value}'),
                label: 'Maximum',
                initial: range.max == null ? '' : formatNumber(range.max!),
                onChanged: (text) =>
                    set(NumberRange(min: range.min, max: _number(text))),
              ),
            ),
          ],
        );

      case ColumnType.duration:
        final range = filter is DurationRange ? filter : const DurationRange();
        return Row(
          children: [
            Expanded(
              child: _Field(
                key: ValueKey('filter-dmin-${column.id.value}'),
                label: 'Au moins (h)',
                initial: _hours(range.min),
                onChanged: (text) =>
                    set(DurationRange(min: _duration(text), max: range.max)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _Field(
                key: ValueKey('filter-dmax-${column.id.value}'),
                label: 'Au plus (h)',
                initial: _hours(range.max),
                onChanged: (text) =>
                    set(DurationRange(min: range.min, max: _duration(text))),
              ),
            ),
          ],
        );

      case ColumnType.date:
        final range = filter is DateRange ? filter : const DateRange();
        return Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'À partir du',
                value: range.from,
                onChanged: (date) => set(DateRange(from: date, to: range.to)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _DateButton(
                label: 'Jusqu\'au',
                value: range.to,
                onChanged: (date) => set(DateRange(from: range.from, to: date)),
              ),
            ),
          ],
        );

      case ColumnType.boolean:
        final value = filter is BoolIs ? filter.value : null;
        return Column(
          children: [
            PanelItem(
              label: 'Tous',
              selected: value == null,
              onTap: () => set(null),
            ),
            PanelItem(
              label: 'Vrai',
              selected: value == true,
              onTap: () => set(const BoolIs(true)),
            ),
            PanelItem(
              label: 'Faux',
              selected: value == false,
              onTap: () => set(const BoolIs(false)),
            ),
          ],
        );

      case ColumnType.singleCategory:
      case ColumnType.multiCategory:
        final rows = ref.watch(rowsProvider(sheetId)).value ?? const [];
        final all = categoriesOf(column, rows);
        final picked = filter is CategoryAnyOf
            ? filter.categories
            : const <String>{};
        if (all.isEmpty) return const _Empty();
        return Column(
          children: [
            for (final category in all)
              _Check(
                label: category,
                checked: picked.contains(category),
                onChanged: (on) => set(
                  CategoryAnyOf(
                    on
                        ? {...picked, category}
                        : picked.where((c) => c != category),
                  ),
                ),
              ),
          ],
        );

      case ColumnType.reference:
        final rows = ref.watch(rowsProvider(sheetId)).value ?? const [];
        final target = column.reference?.targetSheetId;
        final labels = target == null
            ? const <RowId, String>{}
            : ref.watch(rowLabelsProvider(target));
        final used = <RowId>{
          for (final row in rows)
            if (row[column.id] case ReferenceValue(:final rowIds)) ...rowIds,
        };
        final picked = filter is ReferenceAnyOf
            ? filter.rowIds
            : const <RowId>{};
        if (used.isEmpty) return const _Empty();
        return Column(
          children: [
            for (final id in used)
              _Check(
                label: labels[id] ?? 'Ligne supprimée',
                checked: picked.contains(id),
                onChanged: (on) => set(
                  ReferenceAnyOf(
                    on ? {...picked, id} : picked.where((r) => r != id),
                  ),
                ),
              ),
          ],
        );
    }
  }

  static double? _number(String text) =>
      switch (parseCellInput(ColumnType.number, text)) {
        CellInputOk(value: NumberValue(:final number)) => number,
        _ => null,
      };

  static Duration? _duration(String text) {
    final hours = _number(text);
    return hours == null || hours < 0
        ? null
        : Duration(minutes: (hours * 60).round());
  }

  static String _hours(Duration? duration) =>
      duration == null ? '' : formatNumber(duration.inMinutes / 60);
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: Text(
      'Aucune valeur dans cette colonne pour l\'instant.',
      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Checkbox(
              value: checked,
              activeColor: AppColors.accent,
              onChanged: (next) => onChanged(next ?? false),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateValue? value;
  final ValueChanged<DateValue?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: value?.date ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200),
                    );
                    if (picked != null) {
                      onChanged(DateValue.fromDateTime(picked));
                    }
                  },
                  child: Text(
                    value == null
                        ? 'Choisir'
                        : formatCell(value, ColumnType.date),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (value != null)
                IconButton(
                  tooltip: 'Retirer la date',
                  iconSize: 14,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
