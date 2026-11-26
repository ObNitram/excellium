import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';

/// Sélecteur à segments : un seul choix actif parmi quelques options.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// Les options, chacune avec son libellé et une icône facultative.
  final List<({T value, String label, IconData? icon})> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E9ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            Semantics(
              button: true,
              selected: option.value == selected,
              child: InkWell(
                onTap: () => onSelected(option.value),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: option.value == selected ? AppColors.surface : null,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: option.value == selected
                        ? const [
                            BoxShadow(
                              color: Color(0x2E1C2026),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (option.icon != null) ...[
                        Icon(option.icon, size: 14, color: AppColors.text),
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
        ],
      ),
    );
  }
}
