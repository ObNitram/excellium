import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';

/// Un bouton qui ouvre un panneau flottant sous lui.
///
/// Contrairement à un menu, le panneau peut contenir n'importe quel contenu
/// (cases à cocher, champs de saisie) et reste ouvert pendant qu'on s'en sert.
/// Il se ferme par un clic en dehors, par Échap ou par l'appel à `close`.
class Popover extends StatefulWidget {
  const Popover({
    super.key,
    required this.anchorBuilder,
    required this.panelBuilder,
    this.width = 280,
    this.above = false,
  });

  /// Construit le bouton ; `toggle` ouvre ou ferme le panneau.
  final Widget Function(BuildContext context, VoidCallback toggle, bool isOpen)
  anchorBuilder;

  /// Construit le contenu du panneau ; `close` le ferme.
  final Widget Function(BuildContext context, VoidCallback close) panelBuilder;

  final double width;

  /// Ouvre le panneau au-dessus du bouton plutôt qu'en dessous : pour un
  /// bouton placé en bas de la fenêtre.
  final bool above;

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();

  void _toggle() => setState(_controller.toggle);

  void _close() {
    if (_controller.isShowing) setState(_controller.hide);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (overlayContext) {
          // Près du bord droit de la fenêtre, le panneau s'aligne sur la
          // droite du bouton pour rester entièrement visible.
          final box = context.findRenderObject();
          final left = box is RenderBox && box.hasSize
              ? box.localToGlobal(Offset.zero).dx
              : 0.0;
          final toLeft =
              left + widget.width > MediaQuery.sizeOf(overlayContext).width - 8;
          final vertical = widget.above ? 1.0 : -1.0;
          final horizontal = toLeft ? 1.0 : -1.0;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                // Au-dessus : bas du panneau sur le haut du bouton ; sinon
                // haut du panneau sous le bouton.
                targetAnchor: Alignment(horizontal, -vertical),
                followerAnchor: Alignment(horizontal, vertical),
                offset: Offset(0, widget.above ? -4 : 4),
                child: Align(
                  alignment: Alignment(horizontal, vertical),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape): _close,
                    },
                    // Le panneau prend le focus à l'ouverture : Échap le ferme
                    // même s'il ne contient aucun champ de saisie.
                    child: FocusScope(
                      autofocus: true,
                      child: Material(
                        key: const Key('popover-panel'),
                        elevation: 8,
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.headerLine),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: widget.width,
                            maxWidth: widget.width,
                            maxHeight: 520,
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(6),
                            child: widget.panelBuilder(overlayContext, _close),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.anchorBuilder(context, _toggle, _controller.isShowing),
      ),
    );
  }
}

/// Petite action texte, à droite d'un titre de panneau.
class PanelAction extends StatelessWidget {
  const PanelAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 22),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Titre de section dans un panneau.
class PanelTitle extends StatelessWidget {
  const PanelTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Hauteur fixe : le titre ne bouge pas quand son action apparaît.
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(10, 2, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Ligne cliquable d'un panneau, avec icône, libellé et coche éventuelle.
class PanelItem extends StatelessWidget {
  const PanelItem({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.danger = false,
    this.trailing,
  });

  final String label;

  /// `null` désactive l'entrée.
  final VoidCallback? onTap;
  final IconData? icon;
  final bool selected;

  /// Action destructrice, écrite en rouge.
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.textMuted
        : danger
        ? AppColors.danger
        : (selected ? AppColors.accent : AppColors.text);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentTint : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected || danger ? color : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              ?trailing,
              if (selected && trailing == null)
                Icon(Icons.check, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton à bordure des barres, avec flèche, qui sert d'ancre à un panneau.
class BarButton extends StatelessWidget {
  const BarButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.strong = false,
    this.dropdown = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool strong;
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.fieldBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.text),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (dropdown)
                const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: AppColors.text,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
