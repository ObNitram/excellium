import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import 'workbook_providers.dart';

/// Barre d'onglets des feuilles, avec le bouton d'ajout à droite des onglets.
class SheetTabs extends ConsumerWidget {
  const SheetTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheets = ref.watch(sheetsProvider).value ?? const [];
    final active = ref.watch(activeSheetProvider);

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
                    _Tab(
                      name: sheet.name,
                      selected: sheet.id == active?.id,
                      onTap: () => ref
                          .read(chosenSheetIdProvider.notifier)
                          .choose(sheet.id),
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
              final created = await ref
                  .read(workbookServiceProvider)
                  .createSheet();
              ref.read(chosenSheetIdProvider.notifier).choose(created.id);
            },
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
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
                color: selected ? AppColors.headerLine : Colors.transparent,
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
      ),
    );
  }
}
