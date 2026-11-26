import 'package:excellium_core/excellium_core.dart';

import '../../shared/app_icons.dart';

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
    ColumnType.formula => 'Formule',
  };

  AppIconData get icon => switch (this) {
    ColumnType.text => AppIcons.text,
    ColumnType.number => AppIcons.number,
    ColumnType.percent => AppIcons.percent,
    ColumnType.date => AppIcons.date,
    ColumnType.duration => AppIcons.duration,
    ColumnType.singleCategory => AppIcons.singleCategory,
    ColumnType.multiCategory => AppIcons.multiCategory,
    ColumnType.boolean => AppIcons.boolean,
    ColumnType.reference => AppIcons.reference,
    ColumnType.formula => AppIcons.formula,
  };

  /// Exemple de valeur, affiché à droite du type dans le menu de colonne.
  String get hint => switch (this) {
    ColumnType.text => 'Abc',
    ColumnType.number => '123',
    ColumnType.percent => '12,5 %',
    ColumnType.date => '31/12/2026',
    ColumnType.duration => '1 h 30',
    ColumnType.singleCategory => 'Une valeur',
    ColumnType.multiCategory => 'Plusieurs',
    ColumnType.boolean => 'Vrai / Faux',
    ColumnType.reference => 'Autre feuille',
    ColumnType.formula => 'A × B',
  };

  bool get isCategory =>
      this == ColumnType.singleCategory || this == ColumnType.multiCategory;

  /// Les valeurs de ce type sont du texte que l'on peut mettre en gras, en
  /// italique ou souligner.
  bool get hasTextStyle => switch (this) {
    ColumnType.text ||
    ColumnType.number ||
    ColumnType.percent ||
    ColumnType.date ||
    ColumnType.duration ||
    ColumnType.formula => true,
    _ => false,
  };
}

/// Titre d'une colonne dans les menus : son nom, sinon « Colonne A ».
String columnTitle(ColumnDef column) => column.name.trim().isEmpty
    ? 'Colonne ${column.letter}'
    : column.name.trim();
