import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';
import 'app_icons.dart';
import 'pixel_lines.dart';

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
    this.dx = 0,
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

  /// Décalage horizontal du panneau par rapport au bouton : le menu d'une
  /// colonne s'aligne sur le bord gauche de la colonne, pas sur sa flèche.
  final double dx;

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();

  final _scope = FocusScopeNode(debugLabel: 'Panneau');

  /// Ce qui avait le focus avant l'ouverture (le champ de la barre
  /// d'édition, par exemple) : il le retrouve à la fermeture.
  FocusNode? _previous;

  void _toggle() => _controller.isShowing ? _close() : _open();

  void _open() {
    _previous = FocusManager.instance.primaryFocus;
    setState(_controller.show);
    // Le panneau prend le focus : Échap le ferme même s'il ne contient aucun
    // champ, et même si l'écran avait déjà le focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.isShowing) _scope.requestFocus();
    });
  }

  void _close() {
    if (!_controller.isShowing) return;
    setState(_controller.hide);
    final previous = _previous;
    _previous = null;
    if (previous != null && previous.context != null && _scope.hasFocus) {
      previous.requestFocus();
    }
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
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
          final left =
              (box is RenderBox && box.hasSize
                  ? box.localToGlobal(Offset.zero).dx
                  : 0.0) +
              widget.dx;
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
                // La maquette ouvre ses panneaux 4 px sous le bouton (34 px
                // sous le haut d'un bouton de 28 px).
                offset: Offset(toLeft ? 0 : widget.dx, widget.above ? -4 : 4),
                child: Align(
                  alignment: Alignment(horizontal, vertical),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape): _close,
                    },
                    // Le panneau prend le focus à l'ouverture : Échap le ferme
                    // même s'il ne contient aucun champ de saisie.
                    child: FocusScope(
                      node: _scope,
                      autofocus: true,
                      child: Container(
                        key: const Key('popover-panel'),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.headerLine),
                          boxShadow: AppShadows.panel,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          type: MaterialType.transparency,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: widget.width,
                              maxWidth: widget.width,
                              maxHeight: 520,
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(6),
                              child: widget.panelBuilder(
                                overlayContext,
                                _close,
                              ),
                            ),
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

/// Petite action texte, à droite d'un titre de panneau (« Tout afficher »,
/// « Effacer »).
class PanelAction extends StatelessWidget {
  const PanelAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 24),
        maximumSize: const Size(double.infinity, 24),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Titre de section dans un panneau, en petites capitales.
class PanelTitle extends StatelessWidget {
  const PanelTitle(this.text, {super.key, this.trailing});

  final String text;

  /// Action à droite du titre. Le titre garde la même hauteur avec ou sans :
  /// il ne bouge pas quand elle apparaît.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Mêmes marges que la maquette : 8 px au-dessus et 6 px sous un titre
    // seul ; un titre avec action est centré sur 28 px.
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: trailing == null
          ? const EdgeInsets.fromLTRB(10, 8, 10, 6)
          : const EdgeInsets.fromLTRB(10, 2, 4, 2),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: AppText.panelTitle)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Texte d'aide dans un panneau.
class PanelNote extends StatelessWidget {
  const PanelNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Text(text, style: AppText.help),
  );
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
    this.height = 36,
    this.radius = 6,
    this.labelPrefix,
  });

  final String label;

  /// `null` désactive l'entrée.
  final VoidCallback? onTap;
  final AppIconData? icon;
  final bool selected;

  /// Action destructrice, écrite en rouge.
  final bool danger;
  final Widget? trailing;

  /// 36 px pour un choix, 38 px pour une action du menu de colonne.
  final double height;

  /// Coins arrondis ; 0 pour les actions du menu de colonne, qui vont d'un
  /// bord à l'autre.
  final double radius;

  /// Début du libellé, en gris (« Type : »).
  final String? labelPrefix;

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
      child: Material(
        color: selected ? AppColors.accentTint : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  AppIcon(
                    icon!,
                    color: selected || danger ? color : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (labelPrefix != null)
                          TextSpan(
                            text: labelPrefix,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        TextSpan(text: label),
                      ],
                    ),
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
                  AppIcon(AppIcons.check, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trait qui sépare deux groupes d'entrées d'un panneau.
class PanelDivider extends StatelessWidget {
  const PanelDivider({super.key});

  @override
  Widget build(BuildContext context) => const LinedBox(
    height: 1,
    edges: [Edges(bottom: Line(AppColors.gridLine))],
  );
}

/// Bouton à bordure de la barre de vue, avec flèche, qui sert d'ancre à un
/// panneau.
class BarButton extends StatelessWidget {
  const BarButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.strong = false,
    this.dropdown = true,
    this.prefix,
    this.accent = false,
  });

  final String label;
  final VoidCallback onPressed;
  final AppIconData? icon;

  /// Libellé en gras (le bouton des vues).
  final bool strong;
  final bool dropdown;

  /// Début du libellé, en gris et en graisse normale (« Vue : »).
  final String? prefix;

  /// Bouton d'action : bordure et texte de la couleur d'accent.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.accent : AppColors.text;
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: accent ? AppColors.accent : AppColors.fieldBorder,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: AppSizes.smallControl,
            padding: EdgeInsets.symmetric(horizontal: accent ? 10 : 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  AppIcon(icon!, size: 14, color: color),
                  const SizedBox(width: 6),
                ],
                Text.rich(
                  TextSpan(
                    children: [
                      if (prefix != null)
                        TextSpan(
                          text: prefix,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      TextSpan(text: label),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: strong || accent
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
                if (dropdown) ...[
                  const SizedBox(width: 6),
                  AppIcon(AppIcons.chevronDown, size: 10, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
