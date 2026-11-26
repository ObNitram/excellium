import 'package:excellium_core/excellium_core.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/drag_data.dart';
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

    return Container(
      height: AppSizes.tabsHeight,
      decoration: const BoxDecoration(
        color: AppColors.header,
        border: Border(top: BorderSide(color: AppColors.headerLine)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
          IconButton(
            tooltip: 'Ajouter une feuille',
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.textSubtle,
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
      padding: EdgeInsets.only(left: 18, right: selected && !floating ? 4 : 18),
      child: Text(
        sheet.name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected || floating ? FontWeight.w600 : FontWeight.w500,
          color: floating ? AppColors.accent : color,
        ),
      ),
    );

    return Container(
      height: AppSizes.tabsHeight,
      decoration: BoxDecoration(
        color: selected ? AppColors.surface : null,
        border: Border(
          bottom: BorderSide(
            width: 2,
            color: selected ? AppColors.accent : Colors.transparent,
          ),
          left: BorderSide(
            width: widget.dropping ? 3 : 1,
            color: widget.dropping
                ? AppColors.accent
                : (selected ? AppColors.headerLine : Colors.transparent),
          ),
          right: BorderSide(
            color: selected ? AppColors.headerLine : Colors.transparent,
          ),
        ),
      ),
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
                  child: SizedBox(
                    width: 24,
                    height: AppSizes.tabsHeight,
                    child: Icon(Icons.arrow_drop_down, size: 18, color: color),
                  ),
                ),
              ),
              panelBuilder: (context, close) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PanelItem(
                    icon: Icons.edit_outlined,
                    label: 'Renommer',
                    onTap: () {
                      close();
                      renameSheet(this.context, ref, sheet);
                    },
                  ),
                  PanelItem(
                    icon: Icons.delete_outline,
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
          if (selected) const SizedBox(width: 6),
        ],
      ),
    );
  }
}
