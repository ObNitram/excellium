import 'package:excellium_core/excellium_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/drag_data.dart';
import '../../shared/providers.dart';
import '../formulas/formula_text.dart';
import '../grid/cell_format.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import '../views/view_providers.dart';

/// Affichage kanban : une colonne « catégorie unique » fournit les étapes, et
/// chaque ligne devient une carte dans l'étape de sa catégorie. Glisser une
/// carte vers une autre étape change la catégorie de la ligne. On peut y créer
/// une carte (une ligne) dans une étape, et une étape (une catégorie).
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

    // Le titre d'une nouvelle carte se saisit quand la colonne de titre est
    // une colonne Texte ; sinon la carte est créée avec sa seule étape.
    final typedTitle = titleColumn?.type == ColumnType.text;
    final selectionNotifier = ref.read(selectionProvider.notifier);

    Future<void> addCard(String step, String title) async {
      final text = title.trim();
      final values = <ColumnId, CellValue>{
        if (step.isNotEmpty) keyColumn.id: CategoryValue.single(step),
        if (typedTitle && text.isNotEmpty) titleColumn!.id: TextValue(text),
      };
      if (values.isEmpty) return;
      final created = await service.addRowWith(sheet.id, values);
      // La carte créée est sélectionnée : la barre d'édition permet de
      // compléter ses autres valeurs.
      if (titleColumn != null) {
        selectionNotifier.select(created.id, titleColumn.id);
      }
    }

    int hiddenIn(String step) =>
        allRows.where((row) => !row.isEmpty && stepOf(row) == step).length -
        rows.where((row) => stepOf(row) == step).length;

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
                // La clé garde l'état de l'étape (saisie d'une carte en
                // cours) quand les étapes changent autour d'elle.
                key: ValueKey('lane-$step'),
                padding: const EdgeInsets.only(right: 12),
                child: _Lane(
                  step: step,
                  hiddenCount: hiddenIn(step),
                  typedTitle: typedTitle,
                  // Sans titre à saisir, une carte « sans étape » serait une
                  // ligne vide : rien à créer.
                  onAddCard: step.isEmpty && !typedTitle
                      ? null
                      : (title) => addCard(step, title),
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
            _AddStep(onAdd: (name) => service.addCategory(keyColumn, name)),
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
      if (column.type == ColumnType.formula) {
        final computed = ref
            .watch(sheetFormulasProvider(row.sheetId))
            .column(column.id);
        final number = computed.values[row.id];
        if (number == null) continue;
        final name = column.name.trim();
        final text = formulaValueText(number, computed.unit);
        fields.add((
          icon: column.type.icon,
          text: name.isEmpty ? text : '$name : $text',
        ));
        continue;
      }
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

class _Lane extends StatefulWidget {
  const _Lane({
    required this.step,
    required this.name,
    required this.cards,
    required this.hiddenCount,
    required this.typedTitle,
    required this.onAddCard,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onDrop,
  });

  /// La catégorie de l'étape ; vide pour « Sans étape ».
  final String step;
  final String name;
  final List<_Card> cards;

  /// Cartes de l'étape que les filtres de la vue masquent.
  final int hiddenCount;

  /// Vrai si une nouvelle carte se crée en saisissant son titre.
  final bool typedTitle;

  /// Crée une carte dans l'étape ; `null` si ce n'est pas possible.
  final Future<void> Function(String title)? onAddCard;
  final bool canMoveLeft;
  final bool canMoveRight;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final ValueChanged<RowId> onDrop;

  @override
  State<_Lane> createState() => _LaneState();
}

class _LaneState extends State<_Lane> {
  final _title = TextEditingController();
  final _focus = FocusNode();
  bool _adding = false;

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    _title.clear();
    setState(() => _adding = false);
  }

  /// Crée la carte et garde le champ ouvert pour saisir la suivante.
  Future<void> _submit() async {
    final text = _title.text.trim();
    if (text.isEmpty) return _close();
    _title.clear();
    _focus.requestFocus();
    await widget.onAddCard!(text);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final cards = widget.cards;
    final hidden = widget.hiddenCount;
    return DragTarget<RowDrag>(
      onAcceptWithDetails: (details) => widget.onDrop(details.data.id),
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
                if (widget.canMoveLeft)
                  IconButton(
                    tooltip: 'Déplacer l\'étape $name vers la gauche',
                    iconSize: 14,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: widget.onMoveLeft,
                  ),
                if (widget.canMoveRight)
                  IconButton(
                    tooltip: 'Déplacer l\'étape $name vers la droite',
                    iconSize: 14,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: widget.onMoveRight,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (cards.isEmpty && !_adding)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Aucune carte',
                  style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
                ),
              ),
            for (final card in cards)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text(
                  hidden > 1
                      ? '$hidden cartes masquées par les filtres'
                      : '1 carte masquée par les filtres',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                  ),
                ),
              ),
            if (widget.onAddCard != null && _adding)
              _InlineField(
                fieldKey: Key('new-card-${widget.step}'),
                controller: _title,
                focusNode: _focus,
                hint: 'Titre de la carte',
                onSubmit: _submit,
                onCancel: _close,
              )
            else if (widget.onAddCard != null)
              _GhostButton(
                key: Key('add-card-${widget.step}'),
                label: 'Ajouter une carte',
                onPressed: widget.typedTitle
                    ? () {
                        setState(() => _adding = true);
                        _focus.requestFocus();
                      }
                    : () => widget.onAddCard!(''),
              ),
          ],
        ),
      ),
    );
  }
}

/// Emplacement, après la dernière étape, pour en créer une nouvelle : elle
/// s'ajoute aux catégories de la colonne.
class _AddStep extends StatefulWidget {
  const _AddStep({required this.onAdd});

  /// Renvoie `false` si l'étape n'a pas pu être ajoutée (nom déjà pris).
  final Future<bool> Function(String name) onAdd;

  @override
  State<_AddStep> createState() => _AddStepState();
}

class _AddStepState extends State<_AddStep> {
  final _name = TextEditingController();
  final _focus = FocusNode();
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    _name.clear();
    setState(() {
      _adding = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final text = _name.text.trim();
    if (text.isEmpty) return _close();
    final added = await widget.onAdd(text);
    if (!mounted) return;
    if (added) {
      _close();
    } else {
      setState(() => _error = 'L\'étape « $text » existe déjà.');
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: _adding
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _InlineField(
                  fieldKey: const Key('new-step'),
                  controller: _name,
                  focusNode: _focus,
                  hint: 'Nom de l\'étape',
                  onSubmit: _submit,
                  onCancel: _close,
                ),
                if (_error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 2),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            )
          : _GhostButton(
              key: const Key('add-step'),
              label: 'Ajouter une étape',
              onPressed: () {
                setState(() => _adding = true);
                _focus.requestFocus();
              },
            ),
    );
  }
}

/// Bouton discret « + … » en bas d'une étape.
class _GhostButton extends StatelessWidget {
  const _GhostButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              const Icon(Icons.add, size: 14, color: AppColors.textSubtle),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champ de saisie sur place : Entrée valide, Échap ou la croix annulent.
class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onSubmit,
    required this.onCancel,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              // Entrée ne doit pas retirer le focus : on enchaîne les saisies.
              onEditingComplete: () {},
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                filled: true,
                fillColor: AppColors.surface,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 9,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Annuler',
            iconSize: 14,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
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
