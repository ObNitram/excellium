import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import 'app_icons.dart';

/// Bouton carré de 32 px des barres (gras, alignement, effacer…). Allumé, il
/// prend la teinte d'accent.
class IconBtn extends StatelessWidget {
  const IconBtn({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
    this.on,
    this.size = AppSizes.control,
    this.iconSize = 16,
    this.color = AppColors.textSubtle,
    this.bordered = false,
    this.hoverColor = AppColors.hover,
  }) : assert(icon != null || child != null);

  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconData? icon;

  /// Contenu à la place d'une icône, par exemple la lettre « G » du gras.
  final Widget? child;

  /// `null` pour un simple bouton, vrai ou faux pour un interrupteur.
  final bool? on;
  final double size;
  final double iconSize;
  final Color color;

  /// Bouton à bordure, sur fond blanc (− et + de la barre d'édition).
  final bool bordered;
  final Color hoverColor;

  @override
  Widget build(BuildContext context) {
    final lit = on ?? false;
    final fg = onPressed == null
        ? AppColors.disabled
        : (lit ? AppColors.accent : color);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        toggled: on,
        label: tooltip,
        enabled: onPressed != null,
        excludeSemantics: true,
        child: Material(
          color: lit
              ? AppColors.accentTint16
              : (bordered ? AppColors.surface : Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: bordered
                ? const BorderSide(color: AppColors.fieldBorder)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onPressed,
            hoverColor: hoverColor,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: fg),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: fg),
                    child: child ?? AppIcon(icon!, size: iconSize, color: fg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trait vertical de 20 px qui sépare deux groupes de boutons.
class VSeparator extends StatelessWidget {
  const VSeparator({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 1,
    height: 20,
    child: ColoredBox(color: AppColors.headerLine),
  );
}

/// Case à cocher de 15 px, comme celles de la maquette.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: value ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: value ? AppColors.accent : AppColors.fieldBorder,
        ),
      ),
      child: value
          ? const AppIcon(AppIcons.check, size: 13, color: AppColors.surface)
          : null,
    );
    final change = onChanged;
    return Semantics(
      checked: value,
      enabled: change != null,
      child: change == null
          ? box
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => change(!value),
                child: box,
              ),
            ),
    );
  }
}

/// Interrupteur de 30 × 18 px des cellules Booléen.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return Semantics(
      toggled: value,
      enabled: change != null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: change == null ? null : () => change(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 18,
            padding: const EdgeInsets.all(2),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? AppColors.accent : AppColors.fieldBorder,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille de catégorie : 20 px de haut, fond teinté.
class CategoryPill extends StatelessWidget {
  const CategoryPill(this.label, {super.key, this.height = 20});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
      ),
    );
  }
}

/// Ligne d'un panneau avec case à cocher : icône de type, libellé et
/// précision à droite (colonnes affichées, colonnes de recherche, valeurs
/// d'un filtre).
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.checked,
    required this.label,
    required this.onChanged,
    this.icon,
    this.detail,
    this.height = 32,
    this.padding = 10,
  });

  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;
  final AppIconData? icon;
  final String? detail;
  final double height;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          children: [
            AppCheckbox(value: checked, onChanged: onChanged),
            const SizedBox(width: 10),
            if (icon != null) ...[
              AppIcon(icon!, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Poignée de redimensionnement : au survol, un trait d'accent de 3 px
/// signale qu'on peut tirer, comme dans la maquette.
class ResizeGrip extends StatefulWidget {
  const ResizeGrip({super.key, required this.vertical, required this.child});

  /// Vrai pour régler une largeur (trait vertical à droite), faux pour une
  /// hauteur (trait horizontal en bas).
  final bool vertical;
  final Widget child;

  @override
  State<ResizeGrip> createState() => _ResizeGripState();
}

class _ResizeGripState extends State<ResizeGrip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_hover)
            IgnorePointer(
              child: Align(
                alignment: widget.vertical
                    ? Alignment.centerRight
                    : Alignment.bottomCenter,
                child: SizedBox(
                  width: widget.vertical ? 3 : double.infinity,
                  height: widget.vertical ? double.infinity : 3,
                  child: const ColoredBox(color: AppColors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Encadré en pointillés des messages d'affichage (« Aucune colonne de type
/// Date… ») : 20 px de marge, bord de 1 px, coins de 8 px.
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, this.maxWidth = 440});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: CustomPaint(
        painter: _DashedBorder(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(8),
        ),
      );
    final paint = Paint()
      ..color = AppColors.fieldBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Tirets de 3 px séparés de 3 px, comme le pointillé d'un navigateur.
    for (final metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}
