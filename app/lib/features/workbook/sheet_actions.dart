import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/confirm.dart';
import '../../shared/providers.dart';

/// Demande un nouveau nom pour [sheet] et l'enregistre.
Future<void> renameSheet(
  BuildContext context,
  WidgetRef ref,
  Sheet sheet,
) async {
  final service = ref.read(workbookServiceProvider);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(sheet: sheet),
  );
  if (name == null) return;
  await service.renameSheet(sheet, name);
}

/// Supprime [sheet] après confirmation. Le message annonce ce qui sera perdu,
/// y compris dans les autres feuilles.
Future<void> deleteSheet(
  BuildContext context,
  WidgetRef ref,
  Sheet sheet,
) async {
  final store = ref.read(storeProvider);
  final service = ref.read(workbookServiceProvider);

  // Colonnes Référence des autres feuilles qui visent celle-ci.
  final linked = <String>[];
  for (final other in await store.sheets.getSheets()) {
    if (other.id == sheet.id) continue;
    for (final column in await store.columns.getColumns(other.id)) {
      if (column.reference?.targetSheetId == sheet.id) {
        linked.add('« ${column.label} » (${other.name})');
      }
    }
  }
  if (!context.mounted) return;

  final message = StringBuffer(
    'Ses colonnes, ses lignes et ses vues enregistrées seront supprimées. '
    'Ctrl+Z annule la suppression.',
  );
  if (linked.isNotEmpty) {
    message.write(
      '\n\n${linked.length > 1 ? 'Les colonnes' : 'La colonne'} '
      '${linked.join(', ')} '
      '${linked.length > 1 ? 'y font référence : elles seront vidées' : 'y fait référence : elle sera vidée'}.',
    );
  }
  final confirmed = await confirmDelete(
    context,
    title: 'Supprimer la feuille « ${sheet.name} » ?',
    message: message.toString(),
  );
  if (confirmed) await service.deleteSheet(sheet.id);
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.sheet});

  final Sheet sheet;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.sheet.name)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.sheet.name.length,
        );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renommer la feuille'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nom de la feuille'),
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
