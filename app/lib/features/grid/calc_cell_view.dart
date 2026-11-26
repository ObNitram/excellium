import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../formulas/formula_text.dart';

/// Une case de calcul : en bas de la grille, ou sur une ligne de
/// regroupement. Elle affiche un texte ou le résultat d'un calcul ; son
/// contenu se saisit dans la barre d'édition.
class CalcCellView extends StatelessWidget {
  const CalcCellView({
    super.key,
    required this.label,
    required this.display,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
    this.background = AppColors.surface,
    this.bottomLine = true,
  });

  /// Nom de la case pour l'accessibilité, par exemple
  /// « Case de calcul 1, colonne Budget ».
  final String label;
  final CalcDisplay display;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;
  final Color background;
  final bool bottomLine;

  @override
  Widget build(BuildContext context) {
    final failed = display.error != null;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          alignment: display.isNumber
              ? Alignment.centerRight
              : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: background,
            border: Border(
              right: const BorderSide(color: AppColors.gridLine),
              bottom: bottomLine
                  ? const BorderSide(color: AppColors.gridLine)
                  : BorderSide.none,
            ),
          ),
          // Cadre de sélection par-dessus : le contenu ne bouge pas.
          foregroundDecoration: selected
              ? BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2),
                )
              : null,
          child: Text(
            display.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: failed
                  ? AppColors.danger
                  : (display.isValue ? AppColors.text : AppColors.textSubtle),
              fontWeight: display.isValue ? FontWeight.w600 : FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
