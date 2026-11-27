import 'package:excellium_core/excellium_core.dart';

import '../grid/cell_format.dart';

/// Texte affiché dans une cellule quand sa formule est refusée.
const String formulaErrorMark = '#ERREUR';

/// Message en clair pour une formule refusée.
String formulaErrorMessage(FormulaError error) {
  final detail = error.detail;
  return switch (error.code) {
    FormulaErrorCode.unexpectedCharacter =>
      'Caractère inattendu : « $detail ».',
    FormulaErrorCode.missingBracket => 'Il manque un crochet fermant « ] ».',
    FormulaErrorCode.missingParenthesis => 'Il manque une parenthèse fermante.',
    FormulaErrorCode.incomplete => 'La formule est incomplète.',
    FormulaErrorCode.unexpectedToken => 'Élément inattendu : « $detail ».',
    FormulaErrorCode.strayArgumentSeparator =>
      'Le point-virgule sépare des colonnes dans une fonction, par exemple '
          'Somme(A; B).',
    FormulaErrorCode.unknownColumn => 'Colonne inconnue : « $detail ».',
    FormulaErrorCode.unknownFunction => 'Fonction inconnue : « $detail ».',
    FormulaErrorCode.wrongArgumentCount =>
      'La fonction $detail n\'a pas le bon nombre d\'éléments.',
    FormulaErrorCode.notNumeric =>
      '« $detail » n\'est pas une colonne numérique. Essayez Nombre($detail).',
    FormulaErrorCode.datesNotComputable =>
      'Les dates acceptent seulement Min, Max et Nombre.',
    FormulaErrorCode.multipleNotCombinable =>
      'Une fonction appliquée à plusieurs colonnes donne plusieurs '
          'résultats : gardez une seule colonne ici.',
    FormulaErrorCode.numberExpected =>
      'La fonction $detail attend un simple nombre en second, par exemple '
          '$detail(Prix; 2).',
    FormulaErrorCode.cyclic => 'Une formule ne peut pas dépendre d\'elle-même.',
    FormulaErrorCode.brokenColumn =>
      'La colonne « $detail » contient une erreur.',
  };
}

/// Texte d'un résultat de formule ; « – » quand il n'y a rien à calculer.
String formulaValueText(double? value, FormulaUnit unit) {
  final cell = formulaAsCell(value, unit);
  return cell == null ? '–' : formatCell(cell.value, cell.type);
}

/// Ce qu'une case de calcul affiche.
typedef CalcDisplay = ({
  String text,

  /// Vrai pour le résultat d'un calcul (affiché en gras).
  bool isValue,

  /// Vrai pour un seul nombre, aligné à droite comme dans la table.
  bool isNumber,

  /// Renseigné quand le calcul est refusé.
  FormulaError? error,
});

CalcDisplay calcDisplay(CalcCell cell) {
  switch (cell) {
    case CalcBlank():
      return (text: '', isValue: false, isNumber: false, error: null);
    case CalcText(:final text):
      return (text: text, isValue: false, isNumber: false, error: null);
    case CalcResult(:final outcome):
      switch (outcome) {
        case FormulaFailure(:final error):
          return (
            text: formulaErrorMark,
            isValue: false,
            isNumber: false,
            error: error,
          );
        case FormulaScalar(:final value, :final unit):
          return (
            text: formulaValueText(value, unit),
            isValue: true,
            isNumber: true,
            error: null,
          );
        case FormulaMultiple(:final parts):
          return (
            text: [
              for (final part in parts)
                '${part.label} ${formulaValueText(part.value, part.unit)}',
            ].join(' · '),
            isValue: true,
            isNumber: false,
            error: null,
          );
        case FormulaColumn(:final values, :final unit):
          final present = values.nonNulls.toList();
          final head = present
              .take(4)
              .map((value) => formulaValueText(value, unit))
              .join(' · ');
          return (
            text: present.isEmpty
                ? 'Aucune valeur'
                : '${present.length} '
                      '${present.length > 1 ? 'valeurs' : 'valeur'} : $head'
                      '${present.length > 4 ? ' …' : ''}',
            isValue: true,
            isNumber: false,
            error: null,
          );
        case FormulaEmpty():
          return (text: '', isValue: false, isNumber: false, error: null);
      }
  }
}
