import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import 'app_icons.dart';

/// Sélecteur à segments : un seul choix actif parmi quelques options.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = 10,
    this.minSegmentWidth = 0,
    this.expanded = false,
  });

  /// Les segments se partagent toute la largeur disponible.
  final bool expanded;

  /// Marge de chaque segment : 10 px, 14 px pour Vrai / Faux.
  final double padding;
  final double minSegmentWidth;

  /// Les options, chacune avec son libellé et une icône facultative.
  final List<({T value, String label, AppIconData? icon})> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final (index, option) in options.indexed) ...[
            if (index > 0) const SizedBox(width: 2),
            _flex(
              Semantics(
                button: true,
                selected: option.value == selected,
                child: Material(
                  color: option.value == selected
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: () => onSelected(option.value),
                    hoverColor: AppColors.hoverOnTint,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: AppSizes.smallControl,
                      constraints: BoxConstraints(minWidth: minSegmentWidth),
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: option.value == selected
                            ? AppShadows.segment
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (option.icon != null) ...[
                            AppIcon(
                              option.icon!,
                              size: 14,
                              color: AppColors.text,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.text,
                              fontWeight: option.value == selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _flex(Widget child) => expanded ? Expanded(child: child) : child;
}
