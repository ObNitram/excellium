import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/providers.dart';

/// Demande un nouveau nom pour [column] et l'enregistre.
Future<void> renameColumn(
  BuildContext context,
  WidgetRef ref,
  ColumnDef column,
) async {
  final service = ref.read(workbookServiceProvider);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(column: column),
  );
  if (name == null) return;
  await service.renameColumn(column, name);
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
