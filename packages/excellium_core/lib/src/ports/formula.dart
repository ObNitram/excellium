import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Interface du moteur de formules (« port »).
///
/// Le cœur métier et l'application ne connaissent que ces types. Le moteur
/// lui-même vit dans un autre paquet (`excellium_formula` aujourd'hui) : on
/// peut le réécrire, ou en brancher un autre, sans toucher au reste.
///
/// Le moteur ne connaît ni les feuilles ni les cellules. Il reçoit un texte
/// et un [FormulaScope] qui lui donne, pour un nom de colonne, une série de
/// valeurs ; il rend un [FormulaOutcome].

/// Unité d'une valeur numérique, pour l'afficher correctement.
///
/// - [duration] : la valeur est un nombre d'heures ;
/// - [date] : la valeur est un nombre de jours depuis le 1er janvier 1970.
enum FormulaUnit { number, percent, duration, date }

/// Ce qu'une formule peut lire sous un nom de colonne.
@immutable
sealed class FormulaOperand {
  const FormulaOperand();
}

/// Une colonne numérique : une valeur par ligne, `null` si la cellule est
/// vide.
final class FormulaSeries extends FormulaOperand {
  const FormulaSeries(
    this.values, {
    this.unit = FormulaUnit.number,
    this.filled,
    this.name = '',
  });

  final List<double?> values;
  final FormulaUnit unit;

  /// Nom affiché de la colonne, pour étiqueter un résultat.
  final String name;

  /// Lignes à compter par une fonction de dénombrement. Par défaut, celles
  /// qui ont une valeur. Une colonne Booléen compte ses cases cochées.
  final List<bool>? filled;

  /// Nombre de lignes renseignées.
  int get filledCount => filled == null
      ? values.where((v) => v != null).length
      : filled!.where((f) => f).length;
}

/// Une colonne non numérique (texte, catégorie, référence) : on peut
/// seulement compter ses cellules renseignées.
final class FormulaLabels extends FormulaOperand {
  const FormulaLabels(this.filled, {required this.name});

  final List<bool> filled;

  /// Nom affiché de la colonne, pour les messages d'erreur.
  final String name;

  int get filledCount => filled.where((f) => f).length;
}

/// Une colonne Formule qui ne se calcule pas : sa formule est en erreur, ou
/// elle dépend d'elle-même ([cyclic]).
final class FormulaBroken extends FormulaOperand {
  const FormulaBroken({required this.name, this.cyclic = false});

  final String name;
  final bool cyclic;
}

/// Donne au moteur les colonnes qu'une formule cite.
abstract interface class FormulaScope {
  /// La colonne nommée [name] (nom ou lettre), ou `null` si elle n'existe pas.
  FormulaOperand? column(String name);
}

/// Pourquoi une formule est refusée.
enum FormulaErrorCode {
  /// Caractère que le moteur ne comprend pas. [FormulaError.detail] : le
  /// caractère.
  unexpectedCharacter,

  /// Il manque le crochet fermant d'un nom de colonne.
  missingBracket,

  /// Il manque une parenthèse fermante.
  missingParenthesis,

  /// La formule s'arrête trop tôt.
  incomplete,

  /// Élément qui n'a rien à faire là. [FormulaError.detail] : l'élément.
  unexpectedToken,

  /// Point-virgule en dehors d'une fonction.
  strayArgumentSeparator,

  /// Colonne inconnue. [FormulaError.detail] : le nom écrit.
  unknownColumn,

  /// Fonction inconnue. [FormulaError.detail] : le nom écrit.
  unknownFunction,

  /// Mauvais nombre d'arguments. [FormulaError.detail] : le nom de la
  /// fonction.
  wrongArgumentCount,

  /// Colonne non numérique utilisée dans un calcul. [FormulaError.detail] :
  /// le nom de la colonne.
  notNumeric,

  /// Opération impossible sur des dates (somme, moyenne, arithmétique).
  datesNotComputable,

  /// Résultat multiple (une fonction appliquée à plusieurs colonnes) utilisé
  /// dans un calcul.
  multipleNotCombinable,

  /// Un paramètre devait être un simple nombre. [FormulaError.detail] : le
  /// nom de la fonction.
  numberExpected,

  /// La formule dépend d'elle-même.
  cyclic,

  /// La formule cite une colonne Formule en erreur. [FormulaError.detail] :
  /// le nom de cette colonne.
  brokenColumn,
}

@immutable
final class FormulaError {
  const FormulaError(this.code, [this.detail = '']);

  final FormulaErrorCode code;

  /// Précision selon le code : un nom de colonne, de fonction, un caractère.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is FormulaError && other.code == code && other.detail == detail;

  @override
  int get hashCode => Object.hash(code, detail);

  @override
  String toString() => 'FormulaError(${code.name}, $detail)';
}

/// Résultat de l'évaluation d'une formule.
@immutable
sealed class FormulaOutcome {
  const FormulaOutcome();
}

/// Le texte était vide.
final class FormulaEmpty extends FormulaOutcome {
  const FormulaEmpty();
}

final class FormulaFailure extends FormulaOutcome {
  const FormulaFailure(this.error);

  final FormulaError error;

  @override
  String toString() => 'FormulaFailure($error)';
}

/// Une seule valeur, par exemple `Somme(Budget)`. [value] est `null` quand il
/// n'y a rien à calculer (colonne vide, division par zéro).
final class FormulaScalar extends FormulaOutcome {
  const FormulaScalar(this.value, [this.unit = FormulaUnit.number]);

  final double? value;
  final FormulaUnit unit;

  @override
  String toString() => 'FormulaScalar($value, ${unit.name})';
}

/// Une valeur par ligne, par exemple `Quantité × Prix`.
final class FormulaColumn extends FormulaOutcome {
  const FormulaColumn(this.values, [this.unit = FormulaUnit.number]);

  final List<double?> values;
  final FormulaUnit unit;

  @override
  String toString() => 'FormulaColumn($values, ${unit.name})';
}

/// Plusieurs valeurs nommées, par exemple `Somme(Budget; Durée)`.
final class FormulaMultiple extends FormulaOutcome {
  const FormulaMultiple(this.parts);

  final List<FormulaPart> parts;

  @override
  String toString() => 'FormulaMultiple($parts)';
}

@immutable
final class FormulaPart {
  const FormulaPart(this.label, this.value, [this.unit = FormulaUnit.number]);

  /// Ce à quoi la valeur se rapporte, en général un nom de colonne.
  final String label;
  final double? value;
  final FormulaUnit unit;

  @override
  bool operator ==(Object other) =>
      other is FormulaPart &&
      other.label == label &&
      other.value == value &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(label, value, unit);

  @override
  String toString() => '$label=$value';
}

/// Façon dont une fonction s'applique.
enum FormulaFunctionKind {
  /// Sur une colonne entière : rend une seule valeur (Somme, Moyenne…).
  column,

  /// Ligne à ligne (Arrondi, Abs…).
  row,
}

/// Description d'une fonction, pour l'aide à la saisie.
@immutable
final class FormulaFunctionInfo {
  const FormulaFunctionInfo({
    required this.name,
    required this.kind,
    this.example = '',
  });

  final String name;
  final FormulaFunctionKind kind;

  /// Exemple d'appel, par exemple `Arrondi(Prix; 2)`.
  final String example;

  @override
  bool operator ==(Object other) =>
      other is FormulaFunctionInfo &&
      other.name == name &&
      other.kind == kind &&
      other.example == example;

  @override
  int get hashCode => Object.hash(name, kind, example);
}

/// Le moteur de formules.
abstract interface class FormulaEngine {
  /// Les fonctions disponibles, dans l'ordre où les proposer.
  List<FormulaFunctionInfo> get functions;

  /// Évalue [source] en lisant les colonnes dans [scope]. Ne lève jamais
  /// d'exception pour une formule incorrecte : rend un [FormulaFailure].
  FormulaOutcome evaluate(String source, FormulaScope scope);
}

/// Égalité de deux listes de valeurs, pour les tests et les comparaisons.
bool sameFormulaValues(List<double?> a, List<double?> b) =>
    const ListEquality<double?>().equals(a, b);
