import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/providers.dart';

import 'package:excellium_core/excellium_core.dart';

import '../calendar/calendar_view.dart';
import '../editing/edit_bar.dart';
import '../grid/sheet_grid.dart';
import '../kanban/kanban_board.dart';
import '../styling/style_bar.dart';
import '../views/view_bar.dart';
import '../views/view_providers.dart';
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
          const StyleBar(),
          const EditBar(),
          if (active != null) ViewBar(key: ValueKey(active.id), sheet: active),
          Expanded(
            child: sheets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Le classeur n\'a pas pu être chargé : $error'),
              ),
              data: (_) => active == null
                  ? const SizedBox.shrink()
                  : _SheetBody(key: ValueKey(active.id), sheet: active),
            ),
          ),
          const SheetTabs(),
        ],
      ),
    );
  }
}

/// Le contenu de la feuille, selon l'affichage choisi dans la vue.
class _SheetBody extends ConsumerWidget {
  const _SheetBody({super.key, required this.sheet});

  final Sheet sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(
      viewSpecProvider(sheet.id).select((spec) => spec.layout.kind),
    );
    return switch (kind) {
      LayoutKind.grid => SheetGrid(sheet: sheet),
      LayoutKind.kanban => KanbanBoard(sheet: sheet),
      LayoutKind.calendar => CalendarView(sheet: sheet),
    };
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.titleBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.gridLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const AppIcon(AppIcons.logo, color: AppColors.surface),
          ),
          const SizedBox(width: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Excellium',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
