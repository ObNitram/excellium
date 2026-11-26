import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../formulas/formula_text.dart';
import 'calc_cell_view.dart';
import 'grid_providers.dart';

/// Nombre de lignes de cases de calcul sous la table.
const int calcRowCount = 12;

/// Hauteur d'une ligne de cases de calcul.
const double calcRowHeight = 30;

/// Barre qui sépare la table du volet des cases de calcul.
///
/// Le bouton « Calculs » replie ou déplie le volet. Le reste de la barre se
/// fait glisser pour régler sa hauteur ; tirée tout en bas, elle le replie.
/// Un double-clic rend la hauteur d'origine.
class CalcPaneBar extends ConsumerStatefulWidget {
  const CalcPaneBar({super.key});

  static const double height = 24;

  @override
  ConsumerState<CalcPaneBar> createState() => _CalcPaneBarState();
}

class _CalcPaneBarState extends ConsumerState<CalcPaneBar> {
  double? _dragHeight;

  @override
  Widget build(BuildContext context) {
    final pane = ref.watch(calcPaneProvider);
    final notifier = ref.read(calcPaneProvider.notifier);
    return Container(
      height: CalcPaneBar.height,
      decoration: BoxDecoration(
        color: AppColors.header,
        border: Border(
          top: const BorderSide(color: AppColors.fieldBorder),
          bottom: pane.hidden
              ? BorderSide.none
              : const BorderSide(color: AppColors.headerLine),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            expanded: !pane.hidden,
            label: pane.hidden
                ? 'Déplier les cases de calcul'
                : 'Replier les cases de calcul',
            excludeSemantics: true,
            child: InkWell(
              onTap: notifier.toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      pane.hidden ? Icons.expand_less : Icons.expand_more,
                      size: 14,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Calculs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!pane.hidden)
            Expanded(
              child: Semantics(
                container: true,
                label: 'Régler la hauteur des cases de calcul',
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeRow,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) => _dragHeight = pane.height,
                    onVerticalDragUpdate: (details) {
                      final start = _dragHeight;
                      if (start == null) return;
                      // Tirer vers le haut agrandit le volet.
                      final next = start - details.delta.dy;
                      _dragHeight = next;
                      if (next < CalcPane.collapseBelow) {
                        _dragHeight = null;
                        notifier.hide();
                      } else {
                        notifier.setHeight(next);
                      }
                    },
                    onVerticalDragEnd: (_) => _dragHeight = null,
                    onDoubleTap: notifier.reset,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.fieldBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Les cases de calcul : une grille libre sous la table, alignée sur ses
/// colonnes. Elle défile verticalement avec sa propre barre ; à
/// l'horizontale, elle suit la table grâce à [horizontal].
class CalcGrid extends ConsumerStatefulWidget {
  const CalcGrid({
    super.key,
    required this.sheet,
    required this.columns,
    required this.widthOf,
    required this.contentWidth,
    required this.horizontal,
  });

  final Sheet sheet;

  /// Les colonnes affichées, dans l'ordre de la table.
  final List<ColumnDef> columns;
  final double Function(ColumnDef column) widthOf;

  /// Largeur du contenu de la table, pour défiler de la même distance.
  final double contentWidth;
  final ScrollController horizontal;

  @override
  ConsumerState<CalcGrid> createState() => _CalcGridState();
}

class _CalcGridState extends ConsumerState<CalcGrid> {
  final _vertical = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formulas = ref.watch(sheetFormulasProvider(widget.sheet.id));
    final selection = ref.watch(selectionProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.contentWidth < constraints.maxWidth
            ? constraints.maxWidth
            : widget.contentWidth;
        return ColoredBox(
          color: AppColors.surface,
          child: Scrollbar(
            controller: _vertical,
            thumbVisibility: true,
            // La liste verticale est à l'intérieur du défilement horizontal.
            notificationPredicate: (notification) => notification.depth == 1,
            child: Scrollbar(
              controller: widget.horizontal,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: widget.horizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: ListView.builder(
                    controller: _vertical,
                    itemCount: calcRowCount,
                    itemExtent: calcRowHeight,
                    itemBuilder: (context, index) => Row(
                      children: [
                        Container(
                          width: AppSizes.rowHeaderWidth,
                          height: calcRowHeight,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.header,
                            border: Border(
                              right: BorderSide(color: AppColors.headerLine),
                              bottom: BorderSide(color: AppColors.headerLine),
                            ),
                          ),
                          child: ExcludeSemantics(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        for (final column in widget.columns)
                          CalcCellView(
                            label:
                                'Case de calcul ${index + 1}, colonne '
                                '${column.label}',
                            display: calcDisplay(
                              formulas.calcCell(column.calcCells[index] ?? ''),
                            ),
                            width: widget.widthOf(column),
                            height: calcRowHeight,
                            selected:
                                selection is CalcCellSelected &&
                                selection.index == index &&
                                selection.columnId == column.id,
                            onTap: () => ref
                                .read(selectionProvider.notifier)
                                .selectCalcCell(index, column.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
