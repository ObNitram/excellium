import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

import 'package:flutter/services.dart';

import '../../shared/app_icons.dart';
import '../../shared/controls.dart';
import '../../shared/workbook_fields.dart';
import '../../shared/providers.dart';

import 'package:excellium_core/excellium_core.dart';

import '../calendar/calendar_view.dart';
import '../editing/edit_bar.dart';
import '../grid/sheet_grid.dart';
import '../kanban/kanban_board.dart';
import '../styling/style_bar.dart';
import '../views/view_bar.dart';
import '../views/view_providers.dart';
import 'menu_bar.dart';
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

    final zoom = ref.watch(zoomProvider);
    return Scaffold(
      // Une portée de focus à part : quand le champ qui avait le focus
      // disparaît (on sélectionne une colonne entière), le focus revient ici
      // et les raccourcis continuent de fonctionner.
      body: FocusScope(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TitleBar(),
            const StyleBar(),
            const EditBar(),
            if (active != null)
              ViewBar(key: ValueKey(active.id), sheet: active),
            Expanded(
              child: sheets.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Le classeur n\'a pas pu être chargé : $error'),
                ),
                data: (_) => active == null
                    ? const SizedBox.shrink()
                    : _Zoomed(
                        zoom: zoom,
                        child: _SheetBody(
                          key: ValueKey(active.id),
                          sheet: active,
                        ),
                      ),
              ),
            ),
            const SheetTabs(),
          ],
        ),
      ),
    );
  }

  /// Raccourcis du classeur : Ctrl+Z et Ctrl+Y (ou Ctrl+Maj+Z) annulent et
  /// rétablissent, Ctrl++, Ctrl+- et Ctrl+0 règlent le zoom.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final zoom = ref.read(zoomProvider.notifier);
    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      zoom.zoomIn();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      zoom.zoomOut();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      zoom.reset();
      return KeyEventResult.handled;
    }
    final undo = key == LogicalKeyboardKey.keyZ && !keyboard.isShiftPressed;
    final redo =
        key == LogicalKeyboardKey.keyY ||
        (key == LogicalKeyboardKey.keyZ && keyboard.isShiftPressed);
    if (!undo && !redo) return KeyEventResult.ignored;
    // Pendant une saisie, ou dans un champ qui n'écrit pas dans le classeur,
    // c'est la frappe qu'on annule.
    if (!WorkbookFields.undoesWorkbook(FocusManager.instance.primaryFocus)) {
      return KeyEventResult.ignored;
    }
    final service = ref.read(workbookServiceProvider);
    undo ? service.undo() : service.redo();
    return KeyEventResult.handled;
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

/// La feuille affichée au zoom choisi : elle est mise en page sur une
/// surface plus petite (ou plus grande) puis agrandie (ou réduite) pour
/// remplir la place, ce qui garde clics et défilement justes.
class _Zoomed extends StatelessWidget {
  const _Zoomed({required this.zoom, required this.child});

  final double zoom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (zoom == 1) return child;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth / zoom;
        final height = box.maxHeight / zoom;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.scale(
              scale: zoom,
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, height: height, child: child),
            ),
          ),
        );
      },
    );
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
          const SizedBox(width: 12),
          const VSeparator(),
          const SizedBox(width: 12),
          const WorkbookMenuBar(),
        ],
      ),
    );
  }
}
