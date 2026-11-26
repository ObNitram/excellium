import '../model/column.dart';
import '../model/row.dart';
import '../model/style.dart';

/// Style effectif d'une cellule, toutes valeurs par défaut résolues.
typedef ResolvedStyle = ({
  bool bold,
  bool italic,
  bool underline,
  TextAlignment align,
  BoolDisplay boolDisplay,
  PercentDisplay percentDisplay,
});

/// Alignement par défaut d'un type : à droite pour les valeurs numériques,
/// centré pour les cases à cocher, à gauche sinon.
TextAlignment defaultAlignment(ColumnType type) => switch (type) {
  ColumnType.number ||
  ColumnType.percent ||
  ColumnType.date ||
  ColumnType.duration => TextAlignment.right,
  ColumnType.boolean => TextAlignment.center,
  _ => TextAlignment.left,
};

/// Combine le style de la colonne et celui de la cellule ; ce dernier
/// l'emporte. Sans [row], renvoie le style de la colonne seule.
ResolvedStyle resolveStyle(ColumnDef column, [SheetRow? row]) {
  final style = column.style.merge(row?.styles[column.id]);
  return (
    bold: style.bold ?? false,
    italic: style.italic ?? false,
    underline: style.underline ?? false,
    align: style.align ?? defaultAlignment(column.type),
    boolDisplay: style.boolDisplay ?? BoolDisplay.checkbox,
    percentDisplay: style.percentDisplay ?? PercentDisplay.value,
  );
}
