import 'package:uuid/uuid.dart';

/// Identifiants typés : impossible de passer un identifiant de colonne là où
/// une ligne est attendue. Ils sont stables et indépendants de la position
/// affichée (lettre de colonne, numéro de ligne, ordre des onglets).
extension type const SheetId(String value) {}

extension type const ColumnId(String value) {}

extension type const RowId(String value) {}

extension type const ViewId(String value) {}

const _uuid = Uuid();

/// Génère un nouvel identifiant unique.
String newId() => _uuid.v4();
