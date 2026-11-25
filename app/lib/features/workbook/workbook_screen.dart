import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/providers.dart';
import '../editing/edit_bar.dart';
import '../grid/sheet_grid.dart';
import 'sheet_tabs.dart';
import 'workbook_providers.dart';

/// Écran principal : barre d'édition, grille de la feuille active, onglets.
class WorkbookScreen extends ConsumerStatefulWidget {
  const WorkbookScreen({super.key});

  @override
  ConsumerState<WorkbookScreen> createState() => _WorkbookScreenState();
}

class _WorkbookScreenState extends ConsumerState<WorkbookScreen> {
  @override
  void initState() {
    super.initState();
    // Un classeur vide reçoit une première feuille.
    Future.microtask(
      () => ref.read(workbookServiceProvider).ensureDefaultSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheets = ref.watch(sheetsProvider);
    final active = ref.watch(activeSheetProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TitleBar(),
          const EditBar(),
          Expanded(
            child: sheets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Le classeur n\'a pas pu être chargé : $error'),
              ),
              data: (_) => active == null
                  ? const SizedBox.shrink()
                  : SheetGrid(key: ValueKey(active.id), sheet: active),
            ),
          ),
          const SheetTabs(),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.gridLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.grid_on, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Excellium',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
