import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import 'column_type_ui.dart';

/// En-tête d'une colonne : icône du type, libellé, et flèche qui ouvre le
/// menu de la colonne.
class ColumnHeader extends ConsumerWidget {
  const ColumnHeader({super.key, required this.column, required this.active});

  final ColumnDef column;

  /// Vrai quand la cellule sélectionnée est dans cette colonne.
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = active ? AppColors.accent : AppColors.textMuted;
    return Container(
      width: column.width,
      height: AppSizes.rowHeight,
      decoration: BoxDecoration(
        color: active ? AppColors.accentTint : AppColors.header,
        border: Border(
          right: const BorderSide(color: AppColors.headerLine),
          bottom: BorderSide(
            width: active ? 2 : 1,
            color: active ? AppColors.accent : AppColors.headerLine,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Icon(column.type.icon, size: 14, color: color),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => _rename(context, ref),
              child: Text(
                column.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ),
          PopupMenuButton<_Action>(
            tooltip: 'Options de la colonne ${column.label}',
            padding: EdgeInsets.zero,
            iconSize: 16,
            icon: Icon(Icons.arrow_drop_down, color: color),
            constraints: const BoxConstraints(minWidth: 260),
            onSelected: (action) => switch (action) {
              _Rename() => _rename(context, ref),
              _SetType(:final type) =>
                ref
                    .read(workbookServiceProvider)
                    .changeColumnType(column, type),
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _Rename(),
                child: _MenuRow(icon: Icons.edit_outlined, label: 'Renommer'),
              ),
              const PopupMenuDivider(),
              for (final type in ColumnType.values)
                PopupMenuItem(
                  value: _SetType(type),
                  child: _MenuRow(
                    icon: type.icon,
                    label: type.label,
                    selected: type == column.type,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(column: column),
    );
    if (name == null) return;
    await ref.read(workbookServiceProvider).renameColumn(column, name);
  }
}

sealed class _Action {
  const _Action();
}

final class _Rename extends _Action {
  const _Rename();
}

final class _SetType extends _Action {
  const _SetType(this.type);

  final ColumnType type;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.text;
    return Row(
      children: [
        Icon(icon, size: 16, color: selected ? color : AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (selected) Icon(Icons.check, size: 16, color: color),
      ],
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.column});

  final ColumnDef column;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.column.name,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Renommer la colonne ${widget.column.letter}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Nom de la colonne',
          hintText: widget.column.letter,
          helperText: 'Laissez vide pour revenir à la lettre.',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Renommer'),
        ),
      ],
    );
  }
}
