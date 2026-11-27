import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers.dart';

/// Les feuilles du classeur, dans l'ordre des onglets.
final sheetsProvider = StreamProvider<List<Sheet>>(
  (ref) => ref.watch(storeProvider).sheets.watchSheets(),
);

/// L'onglet choisi par l'utilisateur, s'il en a choisi un.
final chosenSheetIdProvider = NotifierProvider<ChosenSheet, SheetId?>(
  ChosenSheet.new,
);

class ChosenSheet extends Notifier<SheetId?> {
  @override
  SheetId? build() => null;

  void choose(SheetId id) => state = id;
}

/// La feuille affichée : celle choisie si elle existe encore, sinon la
/// première.
final activeSheetProvider = Provider<Sheet?>((ref) {
  final sheets = ref.watch(sheetsProvider).value ?? const <Sheet>[];
  if (sheets.isEmpty) return null;
  final chosen = ref.watch(chosenSheetIdProvider);
  for (final sheet in sheets) {
    if (sheet.id == chosen) return sheet;
  }
  return sheets.first;
});
