import 'package:meta/meta.dart';

enum TextAlignment { left, center, right }

/// Façon d'afficher un booléen dans la grille.
enum BoolDisplay { checkbox, toggle, text }

/// Façon d'afficher un pourcentage dans la grille.
enum PercentDisplay { value, bar }

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
  });

  static const CellStyle none = CellStyle();

  final bool? bold;
  final bool? italic;
  final bool? underline;
  final TextAlignment? align;
  final BoolDisplay? boolDisplay;
  final PercentDisplay? percentDisplay;

  bool get isEmpty =>
      bold == null &&
      italic == null &&
      underline == null &&
      align == null &&
      boolDisplay == null &&
      percentDisplay == null;

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
        );

  /// Ce style sans les propriétés que [patch] précise.
  CellStyle without(CellStyle patch) => CellStyle(
    bold: patch.bold != null ? null : bold,
    italic: patch.italic != null ? null : italic,
    underline: patch.underline != null ? null : underline,
    align: patch.align != null ? null : align,
    boolDisplay: patch.boolDisplay != null ? null : boolDisplay,
    percentDisplay: patch.percentDisplay != null ? null : percentDisplay,
  );

  @override
  bool operator ==(Object other) =>
      other is CellStyle &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.align == align &&
      other.boolDisplay == boolDisplay &&
      other.percentDisplay == percentDisplay;

  @override
  int get hashCode =>
      Object.hash(bold, italic, underline, align, boolDisplay, percentDisplay);

  @override
  String toString() =>
      'CellStyle(bold: $bold, italic: $italic, underline: $underline, '
      'align: $align, bool: $boolDisplay, percent: $percentDisplay)';
}
