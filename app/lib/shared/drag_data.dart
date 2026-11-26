import 'package:excellium_core/excellium_core.dart';

/// Ce qui est transporté pendant un glisser-déposer.
///
/// Les identifiants typés du cœur sont tous des chaînes à l'exécution : sans
/// ces enveloppes, un onglet glissé pourrait être déposé sur un en-tête de
/// colonne. Chaque classe n'est acceptée que par la cible qui lui correspond.

final class ColumnDrag {
  const ColumnDrag(this.id);

  final ColumnId id;
}

final class SheetDrag {
  const SheetDrag(this.id);

  final SheetId id;
}

/// Une ligne déplacée, depuis une carte de kanban ou une étiquette de
/// calendrier.
final class RowDrag {
  const RowDrag(this.id);

  final RowId id;
}
