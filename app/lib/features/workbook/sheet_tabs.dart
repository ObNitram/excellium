import 'package:excellium_core/excellium_core.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/drag_data.dart';
import '../../shared/pixel_lines.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import 'sheet_actions.dart';
import 'workbook_providers.dart';

/// Barre d'onglets des feuilles. Le bouton d'ajout est à droite des onglets,
/// un onglet se déplace en le faisant glisser sur un autre, se renomme par
/// double-clic et se supprime depuis son menu.
class SheetTabs extends ConsumerWidget {
  const SheetTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheets = ref.watch(sheetsProvider).value ?? const [];
    final active = ref.watch(activeSheetProvider);
    final service = ref.read(workbookServiceProvider);

    void move(SheetId movedId, SheetId targetId) {
      final from = sheets.indexWhere((s) => s.id == movedId);
      final target = sheets.indexWhere((s) => s.id == targetId);
      if (from < 0 || target < 0 || from == target) return;
      // L'onglet déposé prend la place de celui sur lequel il est déposé.
      service.moveSheet(from, target);
    }

    return LinedBox(
      height: AppSizes.tabsHeight,
      color: AppColors.header,
      // Le trait du haut est dessiné par-dessus, comme l'ombre intérieure de
      // la maquette : les onglets gardent toute la hauteur.
      edges: const [Edges(top: Line(AppColors.headerLine))],
      padding: const EdgeInsets.only(left: 6, right: 12),
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final sheet in sheets)
                    DragTarget<SheetDrag>(
                      key: ValueKey(sheet.id),
                      onWillAcceptWithDetails: (d) => d.data.id != sheet.id,
                      onAcceptWithDetails: (d) => move(d.data.id, sheet.id),
                      builder: (context, candidates, _) => _SheetTab(
                        sheet: sheet,
                        selected: sheet.id == active?.id,
                        dropping: candidates.isNotEmpty,
                        // Il reste toujours au moins une feuille.
                        deletable: sheets.length > 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconBtn(
            tooltip: 'Ajouter une feuille',
            icon: AppIcons.plus,
            size: 36,
            onPressed: () async {
              final created = await service.createSheet();
              ref.read(chosenSheetIdProvider.notifier).choose(created.id);
            },
          ),
        ],
      ),
    );
  }
}

/// Un onglet : un clic affiche la feuille, un double-clic la renomme, et la
/// flèche de l'onglet actif ouvre son menu (renommer, supprimer).
class _SheetTab extends ConsumerStatefulWidget {
  const _SheetTab({
    required this.sheet,
    required this.selected,
    required this.dropping,
    required this.deletable,
  });

  final Sheet sheet;
  final bool selected;

  /// Vrai quand un autre onglet est en train d'être déposé sur celui-ci.
  final bool dropping;
  final bool deletable;

  @override
  ConsumerState<_SheetTab> createState() => _SheetTabState();
}

class _SheetTabState extends ConsumerState<_SheetTab> {
  DateTime? _lastTap;

  /// Le double-clic est détecté ici, comme pour les en-têtes de colonne, pour
  /// ne pas retarder le clic simple.
  void _onTap() {
    final now = DateTime.now();
    final last = _lastTap;
    _lastTap = now;
    ref.read(chosenSheetIdProvider.notifier).choose(widget.sheet.id);
    if (last != null && now.difference(last) < kDoubleTapTimeout) {
      _lastTap = null;
      renameSheet(context, ref, widget.sheet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final selected = widget.selected;
    final color = selected ? AppColors.accent : AppColors.textSubtle;

    Widget label({required bool floating}) => Container(
      height: AppSizes.tabsHeight,
      alignment: Alignment.center,
      padding: EdgeInsets.only(left: 18, right: selected && !floating ? 0 : 18),
      child: Text(
        sheet.name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected || floating ? FontWeight.w600 : FontWeight.w500,
          color: floating ? AppColors.accent : color,
        ),
      ),
    );

    // L'onglet actif est blanc, souligné de 2 px et bordé à gauche et à
    // droite ; ces traits sont dessinés par-dessus, sans décaler le texte.
    return LinedBox(
      height: AppSizes.tabsHeight,
      color: selected ? AppColors.surface : null,
      edges: [
        if (selected)
          const Edges(
            left: Line(AppColors.headerLine),
            right: Line(AppColors.headerLine),
            bottom: Line(AppColors.accent, 2),
          ),
        if (widget.dropping) const Edges(left: Line(AppColors.accent, 3)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Draggable<SheetDrag>(
            data: SheetDrag(sheet.id),
            axis: Axis.horizontal,
            feedback: Material(
              elevation: 4,
              color: AppColors.surface,
              child: label(floating: true),
            ),
            childWhenDragging: Opacity(
              opacity: 0.4,
              child: label(floating: false),
            ),
            child: Semantics(
              button: true,
              selected: selected,
              child: InkWell(onTap: _onTap, child: label(floating: false)),
            ),
          ),
          if (selected)
            Popover(
              width: 220,
              above: true,
              anchorBuilder: (context, toggle, isOpen) => Tooltip(
                message: 'Options de la feuille ${sheet.name}',
                child: InkWell(
                  onTap: toggle,
                  hoverColor: Colors.transparent,
                  child: Container(
                    width: 32,
                    height: AppSizes.tabsHeight,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    child: AppIcon(
                      AppIcons.chevronDown,
                      size: 10,
                      color: color,
                    ),
                  ),
                ),
              ),
              panelBuilder: (context, close) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PanelItem(
                    icon: AppIcons.rename,
                    label: 'Renommer',
                    onTap: () {
                      close();
                      renameSheet(this.context, ref, sheet);
                    },
                  ),
                  PanelItem(
                    icon: AppIcons.delete,
                    label: 'Supprimer la feuille',
                    danger: true,
                    onTap: widget.deletable
                        ? () {
                            close();
                            deleteSheet(this.context, ref, sheet);
                          }
                        : null,
                  ),
                  if (!widget.deletable)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 2, 10, 8),
                      child: Text(
                        'Un classeur garde toujours au moins une feuille.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
