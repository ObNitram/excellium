import 'package:excellium_core/excellium_core.dart';

/// Une fonction du langage de formules.
///
/// Pour en ajouter une, écrivez une sous-classe de [ColumnFunction] (une
/// valeur pour toute une colonne) ou de [RowFunction] (une valeur par ligne),
/// puis ajoutez-la à la liste donnée au moteur — voir `standardFunctions`.
/// Rien d'autre n'est à modifier : l'analyse, les erreurs et l'aide à la
/// saisie s'appuient sur cette description.
sealed class FormulaFunction {
  const FormulaFunction();

  /// Nom tel qu'on l'écrit dans une formule, par exemple `Somme`. La casse
  /// et les accents ne comptent pas à la saisie.
  String get name;

  /// Autres noms acceptés.
  List<String> get aliases => const [];

  /// Exemple d'appel montré dans l'aide.
  String get example;

  FormulaFunctionKind get kind;

  FormulaFunctionInfo get info =>
      FormulaFunctionInfo(name: name, kind: kind, example: example);
}

/// Ce qu'une [ColumnFunction] reçoit d'une colonne.
final class ColumnInput {
  const ColumnInput({required this.numbers, required this.filledCount});

  /// Les valeurs numériques de la colonne, cellules vides exclues.
  final List<double> numbers;

  /// Le nombre de cellules renseignées, numériques ou non.
  final int filledCount;
}

/// Fonction de colonne : réduit une colonne entière à une seule valeur
/// (`Somme`, `Moyenne`…). Appelée avec plusieurs colonnes, elle donne un
/// résultat par colonne.
abstract base class ColumnFunction extends FormulaFunction {
  const ColumnFunction();

  @override
  FormulaFunctionKind get kind => FormulaFunctionKind.column;

  /// Faux pour une fonction qui accepte aussi les colonnes non numériques,
  /// comme un dénombrement.
  bool get needsNumbers => true;

  /// Vrai si la fonction a un sens sur des dates (un minimum, un maximum).
  bool get acceptsDates => false;

  /// Unité du résultat d'après celle de la colonne.
  FormulaUnit unitFor(FormulaUnit unit) => unit;

  /// Le résultat, ou `null` s'il n'y a rien à calculer.
  double? compute(ColumnInput input);
}

/// Fonction de ligne : transforme chaque valeur (`Arrondi`, `Abs`…).
///
/// Son premier argument est la valeur ; les suivants sont des paramètres, de
/// simples nombres (le nombre de décimales d'un arrondi).
abstract base class RowFunction extends FormulaFunction {
  const RowFunction();

  @override
  FormulaFunctionKind get kind => FormulaFunctionKind.row;

  /// Nombre minimal et maximal de paramètres après la valeur.
  int get minParameters => 0;
  int get maxParameters => 0;

  double? compute(double value, List<double> parameters);
}
