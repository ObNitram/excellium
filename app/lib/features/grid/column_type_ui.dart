import 'package:excellium_core/excellium_core.dart';
import 'package:material_ui/material_ui.dart';

/// Libellé et icône de chaque type de colonne.
extension ColumnTypeUi on ColumnType {
  String get label => switch (this) {
    ColumnType.text => 'Texte',
    ColumnType.number => 'Nombre',
    ColumnType.percent => 'Pourcentage',
    ColumnType.date => 'Date',
    ColumnType.duration => 'Durée',
    ColumnType.singleCategory => 'Catégorie unique',
    ColumnType.multiCategory => 'Catégorie multiple',
    ColumnType.boolean => 'Booléen',
    ColumnType.reference => 'Référence',
  };

  IconData get icon => switch (this) {
    ColumnType.text => Icons.title,
    ColumnType.number => Icons.tag,
    ColumnType.percent => Icons.percent,
    ColumnType.date => Icons.calendar_today_outlined,
    ColumnType.duration => Icons.schedule,
    ColumnType.singleCategory => Icons.label_outline,
    ColumnType.multiCategory => Icons.label_important_outline,
    ColumnType.boolean => Icons.check_box_outlined,
    ColumnType.reference => Icons.link,
  };

  /// Les valeurs s'alignent à droite pour les types numériques.
  bool get alignsRight => switch (this) {
    ColumnType.number ||
    ColumnType.percent ||
    ColumnType.date ||
    ColumnType.duration => true,
    _ => false,
  };
}
