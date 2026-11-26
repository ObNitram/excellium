import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/drag_data.dart';
import '../../shared/providers.dart';
import 'workbook_providers.dart';

/// Barre d'onglets des feuilles. Le bouton d'ajout est à droite des onglets,
/// et un onglet se déplace en le faisant glisser sur un autre.
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
                      onWillAcceptWithDetails: (d) => d.data.id != sheet.id,
                      onAcceptWithDetails: (d) => move(d.data.id, sheet.id),
                      builder: (context, candidates, _) => Draggable<SheetDrag>(
                        data: SheetDrag(sheet.id),
                        axis: Axis.horizontal,
                        feedback: Material(
                          elevation: 4,
                          child: _Tab(
                            name: sheet.name,
                            selected: true,
                            dropping: false,
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: _Tab(
                            name: sheet.name,
                            selected: sheet.id == active?.id,
                            dropping: false,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => ref
                              .read(chosenSheetIdProvider.notifier)
                              .choose(sheet.id),
                          child: _Tab(
                            name: sheet.name,
                            selected: sheet.id == active?.id,
                            dropping: candidates.isNotEmpty,
                          ),
                        ),
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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.name,
    required this.selected,
    required this.dropping,
  });

  final String name;
  final bool selected;

  /// Vrai quand un autre onglet est en train d'être déposé sur celui-ci.
  final bool dropping;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Container(
        height: AppSizes.tabsHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : null,
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: selected ? AppColors.accent : Colors.transparent,
            ),
            left: BorderSide(
              width: dropping ? 3 : 1,
              color: dropping
                  ? AppColors.accent
                  : (selected ? AppColors.headerLine : Colors.transparent),
            ),
            right: BorderSide(
              color: selected ? AppColors.headerLine : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.accent : AppColors.textSubtle,
          ),
        ),
      ),
    );
  }
}
