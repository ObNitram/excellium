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
  CellFont font,

  /// Taille en points.
  int fontSize,

  /// Couleurs en ARGB ; `null` : celle de l'interface.
  int? textColor,
  int? fillColor,
  CellBorder border,
  bool wrap,
  NumberDisplay numberFormat,

  /// Décimales fixes ; `null` : sans zéros inutiles.
  int? decimals,
});

/// Alignement par défaut d'un type : à droite pour les valeurs numériques,
/// centré pour les cases à cocher, à gauche sinon.
TextAlignment defaultAlignment(ColumnType type) => switch (type) {
  ColumnType.number ||
  ColumnType.percent ||
  ColumnType.date ||
  ColumnType.duration ||
  ColumnType.formula => TextAlignment.right,
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
    font: style.font ?? CellFont.sans,
    fontSize: style.fontSize ?? CellStyle.defaultFontSize,
    // 0 : réglé explicitement sur « par défaut ».
    textColor: style.textColor == 0 ? null : style.textColor,
    fillColor: style.fillColor == 0 ? null : style.fillColor,
    border: style.border ?? CellBorder.none,
    wrap: style.wrap ?? false,
    numberFormat: style.numberFormat ?? NumberDisplay.automatic,
    // -1 : réglé explicitement sur « automatique ».
    decimals: (style.decimals ?? -1) < 0 ? null : style.decimals,
  );
}
