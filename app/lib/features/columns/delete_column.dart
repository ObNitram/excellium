import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/confirm.dart';
import '../../shared/providers.dart';
import '../grid/grid_providers.dart';
import '../views/view_providers.dart';

/// Supprime [column] après confirmation, et la retire de la vue en cours.
Future<void> deleteColumn(BuildContext context, ColumnDef column) async {
  // Le menu qui lance la suppression se ferme aussitôt : on garde le
  // conteneur de providers plutôt que la référence du menu, qui ne sera plus
  // utilisable après la confirmation.
  final container = ProviderScope.containerOf(context, listen: false);
  final service = container.read(workbookServiceProvider);
  final rows = container.read(rowsProvider(column.sheetId)).value ?? const [];
  final filled = rows.where((row) => row[column.id] != null).length;

  final confirmed = await confirmDelete(
    context,
    title: 'Supprimer la colonne « ${column.label} » ?',
    message: switch (filled) {
      0 => 'Elle ne contient aucune valeur. Ctrl+Z annule la suppression.',
      1 =>
        'La valeur qu\'elle contient sera supprimée. Ctrl+Z annule la '
            'suppression.',
      _ =>
        'Les $filled valeurs qu\'elle contient seront supprimées. Ctrl+Z '
            'annule la suppression.',
    },
  );
  if (!confirmed) return;
  if (await service.deleteColumn(column)) {
    container
        .read(viewSpecProvider(column.sheetId).notifier)
        .forgetColumn(column.id);
    if (container.read(selectionProvider)?.columnId == column.id) {
      container.read(selectionProvider.notifier).clear();
    }
  }
}
