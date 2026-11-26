import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/segmented.dart';
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
          hint: 'Contient…',
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
                key: const Key('filter-date-from'),
                value: range.from,
                onChanged: (date) => set(DateRange(from: date, to: range.to)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _DateButton(
                label: 'Jusqu’au',
                key: const Key('filter-date-to'),
                value: range.to,
                onChanged: (date) => set(DateRange(from: range.from, to: date)),
              ),
            ),
          ],
        );

      case ColumnType.boolean:
        final value = filter is BoolIs ? filter.value : null;
        return Segmented<bool?>(
          expanded: true,
          padding: 8,
          selected: value,
          onSelected: (next) => set(next == null ? null : BoolIs(next)),
          options: const [
            (value: null, label: 'Tous', icon: null),
            (value: true, label: 'Vrai', icon: null),
            (value: false, label: 'Faux', icon: null),
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
        return _List(
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
        return _List(
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
    padding: EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      'Aucune valeur dans cette colonne pour l\'instant.',
      style: AppText.help,
    ),
  );
}

/// Liste des valeurs à cocher, qui défile au-delà de 156 px.
class _List extends StatelessWidget {
  const _List({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 156),
    child: SingleChildScrollView(
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) const SizedBox(height: 2),
            child,
          ],
        ],
      ),
    ),
  );
}

/// Champ de filtre. Un champ de plage a son libellé au-dessus ; le champ
/// texte a un simple texte indicatif.
class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.label,
    required this.initial,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  /// Texte indicatif ; sans lui, [label] est écrit au-dessus du champ.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final field = SizedBox(
      height: 32,
      child: TextFormField(
        key: Key('filter-field-$label'),
        initialValue: initial,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
        ),
      ),
    );
    if (hint != null) return field;
    return _Labelled(label: label, child: field);
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
      ),
      const SizedBox(height: 4),
      child,
    ],
  );
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
  Widget build(BuildContext context) => CheckRow(
    checked: checked,
    label: label,
    onChanged: onChanged,
    height: 30,
    padding: 6,
  );
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateValue? value;
  final ValueChanged<DateValue?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Même allure qu'un champ date : un cadre de 32 px avec la date, et une
    // croix pour la retirer.
    return _Labelled(
      label: label,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.fieldBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value?.date ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2200),
            );
            if (picked != null) onChanged(DateValue.fromDateTime(picked));
          },
          child: Container(
            height: 30,
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? 'jj/mm/aaaa'
                        : formatCell(value, ColumnType.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.text,
                    ),
                  ),
                ),
                if (value != null)
                  IconBtn(
                    tooltip: 'Retirer la date',
                    icon: AppIcons.close,
                    iconSize: 12,
                    size: 28,
                    onPressed: () => onChanged(null),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: AppIcon(
                      AppIcons.calendar,
                      size: 14,
                      color: AppColors.textSubtle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
