import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/popover.dart';

/// Couleur proposée, avec son nom pour l'infobulle et l'accessibilité.
typedef NamedColor = ({int value, String name});

/// Couleurs du texte, foncées pour rester lisibles sur fond blanc.
const List<NamedColor> textColors = [
  (value: 0xFF1C2026, name: 'Noir'),
  (value: 0xFF5A6270, name: 'Gris'),
  (value: 0xFFB3261E, name: 'Rouge'),
  (value: 0xFFB4480F, name: 'Orange'),
  (value: 0xFF8A6D00, name: 'Jaune'),
  (value: 0xFF0B6E63, name: 'Vert'),
  (value: 0xFF3D4FD6, name: 'Bleu'),
  (value: 0xFF6B3FA0, name: 'Violet'),
];

/// Couleurs de fond, claires pour que le texte reste lisible.
const List<NamedColor> fillColors = [
  (value: 0xFFF4F5F7, name: 'Gris clair'),
  (value: 0xFFE3E6EA, name: 'Gris'),
  (value: 0xFFFDECEA, name: 'Rouge clair'),
  (value: 0xFFFFF0E0, name: 'Orange clair'),
  (value: 0xFFFFF8D6, name: 'Jaune clair'),
  (value: 0xFFE6F4EA, name: 'Vert clair'),
  (value: 0xFFE4E6F9, name: 'Bleu clair'),
  (value: 0xFFF0E8F8, name: 'Violet clair'),
];

/// Bouton « couleur du texte » (un A souligné de la couleur) ou
/// « couleur de remplissage » (une goutte), qui ouvre une palette.
class ColorButton extends StatelessWidget {
  const ColorButton.text({
    super.key,
    required this.current,
    required this.onPicked,
  }) : fill = false;

  const ColorButton.fill({
    super.key,
    required this.current,
    required this.onPicked,
  }) : fill = true;

  final bool fill;

  /// La couleur actuelle ; `null` : celle par défaut.
  final int? current;

  /// Reçoit la couleur choisie, ou `null` pour revenir à celle par défaut.
  final ValueChanged<int?> onPicked;

  @override
  Widget build(BuildContext context) {
    final title = fill ? 'Couleur de remplissage' : 'Couleur du texte';
    // Le trait sous le bouton montre la couleur en cours ; un remplissage
    // absent est un trait blanc bordé de gris.
    final swatch = Container(
      width: 14,
      height: 3,
      decoration: BoxDecoration(
        color: Color(current ?? (fill ? 0xFFFFFFFF : 0xFF1C2026)),
        borderRadius: BorderRadius.circular(1),
        border: fill && current == null
            ? Border.all(color: const Color(0xFF8A919C))
            : null,
      ),
    );
    return Popover(
      width: 232,
      anchorBuilder: (context, toggle, _) => IconBtn(
        tooltip: title,
        onPressed: toggle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (fill)
              const AppIcon(AppIcons.fill, size: 14)
            else
              const Text(
                'A',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            SizedBox(height: fill ? 2 : 3),
            swatch,
          ],
        ),
      ),
      panelBuilder: (context, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelTitle(title),
          PanelItem(
            label: fill ? 'Aucun remplissage' : 'Couleur par défaut',
            selected: current == null,
            onTap: () {
              onPicked(null);
              close();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final color in fill ? fillColors : textColors)
                  _Swatch(
                    color: color,
                    selected: current == color.value,
                    onTap: () {
                      onPicked(color.value);
                      close();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final NamedColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: color.name,
      child: Semantics(
        button: true,
        selected: selected,
        label: color.name,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 44,
            height: 28,
            decoration: BoxDecoration(
              color: Color(color.value),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.headerLine,
                width: selected ? 2 : 1,
              ),
            ),
            child: selected
                ? AppIcon(
                    AppIcons.check,
                    size: 14,
                    color: color.value == 0xFF1C2026 || color.value < 0xFF800000
                        ? AppColors.surface
                        : AppColors.text,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
