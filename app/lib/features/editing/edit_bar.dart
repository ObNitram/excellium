import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';

/// Barre d'édition : remplit la cellule sélectionnée selon le type de sa
/// colonne.
class EditBar extends ConsumerStatefulWidget {
  const EditBar({super.key});

  @override
  ConsumerState<EditBar> createState() => _EditBarState();
}

class _EditBarState extends ConsumerState<EditBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  CellInputError? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Aligne le champ sur la cellule quand la sélection ou sa valeur change.
  void _sync(SelectedCell? cell) {
    final text = cell == null ? '' : cellInputText(cell.row[cell.column.id]);
    if (_controller.text != text) _controller.text = text;
    if (_error != null) setState(() => _error = null);
  }

  /// Valide la saisie. Si elle est acceptée, la sélection passe à la ligne
  /// suivante et le champ garde le focus, pour enchaîner les saisies comme
  /// dans un tableur. Si elle est refusée, le texte reste à corriger.
  Future<void> _submit(SelectedCell cell) async {
    final error = await ref
        .read(workbookServiceProvider)
        .enterText(cell.row, cell.column, _controller.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      final rows =
          ref.read(rowsProvider(cell.row.sheetId)).value ?? const <SheetRow>[];
      final index = rows.indexWhere((row) => row.id == cell.row.id);
      if (index >= 0 && index + 1 < rows.length) {
        ref
            .read(selectionProvider.notifier)
            .select(rows[index + 1].id, cell.column.id);
      }
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedCellProvider, (_, next) => _sync(next));
    final cell = ref.watch(selectedCellProvider);

    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.barHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.headerLine)),
      ),
      child: cell == null
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sélectionnez une cellule pour la modifier.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Reference('${cell.column.letter}${cell.row.position + 1}'),
                    const SizedBox(width: 10),
                    Icon(
                      cell.column.type.icon,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cell.column.type.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _editor(cell)),
                  ],
                ),
                if (_error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _message(error),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
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

  Widget _editor(SelectedCell cell) {
    final service = ref.read(workbookServiceProvider);
    switch (cell.column.type) {
      case ColumnType.boolean:
        final value = cell.row[cell.column.id];
        final checked = value is BoolValue && value.value;
        return Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Vrai')),
              ButtonSegment(value: false, label: Text('Faux')),
            ],
            selected: {checked},
            onSelectionChanged: (selection) => service.setValue(
              cell.row,
              cell.column,
              BoolValue(selection.first),
            ),
          ),
        );

      case ColumnType.reference:
        return const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Le choix d\'une ligne référencée n\'est pas encore disponible.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        );

      case ColumnType.text:
      case ColumnType.number:
      case ColumnType.percent:
      case ColumnType.date:
      case ColumnType.duration:
      case ColumnType.singleCategory:
      case ColumnType.multiCategory:
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 13),
          textAlign: cell.column.type.alignsRight
              ? TextAlign.right
              : TextAlign.left,
          decoration: InputDecoration(
            isDense: true,
            hintText: _hint(cell.column.type),
            border: const OutlineInputBorder(),
            enabledBorder: _error == null
                ? null
                : const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.danger),
                  ),
            focusedBorder: _error == null
                ? null
                : const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.danger, width: 2),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            suffixText: cell.column.type == ColumnType.percent ? '%' : null,
          ),
          onSubmitted: (_) => _submit(cell),
        );
    }
  }

  static String _hint(ColumnType type) => switch (type) {
    ColumnType.text => 'Saisir un texte',
    ColumnType.number || ColumnType.percent => '0',
    ColumnType.date => 'JJ/MM/AAAA',
    ColumnType.duration => '1:30',
    ColumnType.singleCategory => 'Une catégorie',
    ColumnType.multiCategory => 'Catégories séparées par des virgules',
    ColumnType.boolean || ColumnType.reference => '',
  };

  static String _message(CellInputError error) => switch (error) {
    CellInputError.notANumber => 'Saisissez un nombre, par exemple 12,5.',
    CellInputError.notADate => 'Saisissez une date, par exemple 04/12/2026.',
    CellInputError.notADuration =>
      'Saisissez une durée, par exemple 1:30 ou 45 min.',
    CellInputError.notABoolean => 'Saisissez vrai ou faux.',
    CellInputError.notTypable => 'Ce type ne se saisit pas au clavier.',
  };
}

class _Reference extends StatelessWidget {
  const _Reference(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
