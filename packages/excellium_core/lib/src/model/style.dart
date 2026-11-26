import 'package:meta/meta.dart';

enum TextAlignment { left, center, right }

/// Façon d'afficher un booléen dans la grille.
enum BoolDisplay { checkbox, toggle, text }

/// Façon d'afficher un pourcentage dans la grille.
enum PercentDisplay { value, bar }

/// Police du texte d'une cellule. L'application associe chacune à une
/// famille de caractères.
enum CellFont {
  /// Sans empattement, la police de l'interface.
  sans,

  /// À empattements.
  serif,

  /// À chasse fixe.
  mono,
}

/// Bordure tracée autour d'une cellule.
enum CellBorder { none, bottom, box }

/// Présentation d'un nombre.
enum NumberDisplay {
  /// Tel que saisi, sans zéros inutiles.
  automatic,

  /// Suivi du symbole €.
  currency,
}

/// Style d'une colonne ou d'une cellule.
///
/// Chaque propriété est facultative : `null` signifie « non précisé ». Le
/// style d'une cellule complète celui de sa colonne (voir [merge]).
@immutable
final class CellStyle {
  const CellStyle({
    this.bold,
    this.italic,
    this.underline,
    this.align,
    this.boolDisplay,
    this.percentDisplay,
    this.font,
    this.fontSize,
    this.textColor,
    this.fillColor,
    this.border,
    this.wrap,
    this.numberFormat,
    this.decimals,
  });

  static const CellStyle none = CellStyle();

  /// Tailles de police proposées, en points.
  static const fontSizes = [8, 9, 10, 11, 12, 14, 18, 24];

  /// Taille par défaut, en points.
  static const defaultFontSize = 10;

  /// Nombre de décimales le plus grand.
  static const maxDecimals = 6;

  final bool? bold;
  final bool? italic;
  final bool? underline;
  final TextAlignment? align;
  final BoolDisplay? boolDisplay;
  final PercentDisplay? percentDisplay;
  final CellFont? font;

  /// Taille en points.
  final int? fontSize;

  /// Couleur du texte, en ARGB sur 32 bits (`0xFF1C2026`) ; 0 revient à la
  /// couleur par défaut, même si la colonne en précise une.
  final int? textColor;

  /// Couleur de fond, en ARGB sur 32 bits ; 0 : pas de fond.
  final int? fillColor;
  final CellBorder? border;

  /// Le texte trop long passe à la ligne au lieu d'être coupé.
  final bool? wrap;
  final NumberDisplay? numberFormat;

  /// Nombre fixe de décimales d'un nombre ; -1 revient à l'affichage sans
  /// zéros inutiles, même si la colonne précise un nombre de décimales.
  final int? decimals;

  bool get isEmpty => this == none;

  /// Ce style complété par [over], dont les propriétés précisées l'emportent.
  CellStyle merge(CellStyle? over) => over == null
      ? this
      : CellStyle(
          bold: over.bold ?? bold,
          italic: over.italic ?? italic,
          underline: over.underline ?? underline,
          align: over.align ?? align,
          boolDisplay: over.boolDisplay ?? boolDisplay,
          percentDisplay: over.percentDisplay ?? percentDisplay,
          font: over.font ?? font,
          fontSize: over.fontSize ?? fontSize,
          textColor: over.textColor ?? textColor,
          fillColor: over.fillColor ?? fillColor,
          border: over.border ?? border,
          wrap: over.wrap ?? wrap,
          numberFormat: over.numberFormat ?? numberFormat,
          decimals: over.decimals ?? decimals,
        );

  /// Ce style sans les propriétés que [patch] précise.
  CellStyle without(CellStyle patch) => CellStyle(
    bold: patch.bold != null ? null : bold,
    italic: patch.italic != null ? null : italic,
    underline: patch.underline != null ? null : underline,
    align: patch.align != null ? null : align,
    boolDisplay: patch.boolDisplay != null ? null : boolDisplay,
    percentDisplay: patch.percentDisplay != null ? null : percentDisplay,
    font: patch.font != null ? null : font,
    fontSize: patch.fontSize != null ? null : fontSize,
    textColor: patch.textColor != null ? null : textColor,
    fillColor: patch.fillColor != null ? null : fillColor,
    border: patch.border != null ? null : border,
    wrap: patch.wrap != null ? null : wrap,
    numberFormat: patch.numberFormat != null ? null : numberFormat,
    decimals: patch.decimals != null ? null : decimals,
  );

  @override
  bool operator ==(Object other) =>
      other is CellStyle &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.align == align &&
      other.boolDisplay == boolDisplay &&
      other.percentDisplay == percentDisplay &&
      other.font == font &&
      other.fontSize == fontSize &&
      other.textColor == textColor &&
      other.fillColor == fillColor &&
      other.border == border &&
      other.wrap == wrap &&
      other.numberFormat == numberFormat &&
      other.decimals == decimals;

  @override
  int get hashCode => Object.hash(
    bold,
    italic,
    underline,
    align,
    boolDisplay,
    percentDisplay,
    font,
    fontSize,
    textColor,
    fillColor,
    border,
    wrap,
    numberFormat,
    decimals,
  );

  @override
  String toString() =>
      'CellStyle(bold: $bold, italic: $italic, underline: $underline, '
      'align: $align, bool: $boolDisplay, percent: $percentDisplay, '
      'font: $font, size: $fontSize, text: $textColor, fill: $fillColor, '
      'border: $border, wrap: $wrap, number: $numberFormat, '
      'decimals: $decimals)';
}
