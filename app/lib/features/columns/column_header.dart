import 'package:excellium_core/excellium_core.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/drag_data.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import '../views/view_providers.dart';
import 'column_menu.dart';
import 'rename_column.dart';

/// En-tête d'une colonne.
///
/// - clic : sélectionne toute la colonne ;
/// - double-clic : renomme ;
/// - glisser : déplace la colonne ;
/// - flèche : ouvre le menu de la colonne ;
/// - bord droit : règle la largeur.
class ColumnHeader extends ConsumerStatefulWidget {
  const ColumnHeader({
    super.key,
    required this.column,
    required this.width,
    required this.allColumns,
  });

  final ColumnDef column;
  final double width;

  /// Toutes les colonnes de la feuille, pour calculer un déplacement.
  final List<ColumnDef> allColumns;

  @override
  ConsumerState<ColumnHeader> createState() => _ColumnHeaderState();
}

class _ColumnHeaderState extends ConsumerState<ColumnHeader> {
  double? _dragStartWidth;
  DateTime? _lastTap;

  /// Un clic sélectionne la colonne tout de suite ; un second clic rapproché
  /// la renomme. Le double-clic est détecté ici plutôt que par le détecteur
  /// de gestes, qui retarderait chaque clic simple pour attendre le second.
  void _onTap() {
    final now = DateTime.now();
    final last = _lastTap;
    _lastTap = now;
    ref.read(selectionProvider.notifier).selectColumn(column.id);
    if (last != null && now.difference(last) < kDoubleTapTimeout) {
      _lastTap = null;
      renameColumn(context, ref, column);
    }
  }

  ColumnDef get column => widget.column;

  void _move(ColumnId movedId) {
    final from = widget.allColumns.indexWhere((c) => c.id == movedId);
    final target = widget.allColumns.indexWhere((c) => c.id == column.id);
    if (from < 0 || target < 0 || from == target) return;
    // La colonne déposée prend la place de celle-ci, comme pour les onglets :
    // déposer sur la voisine échange les deux colonnes.
    ref.read(workbookServiceProvider).moveColumn(column.sheetId, from, target);
  }

  int _indexOf(ColumnId id) => widget.allColumns.indexWhere((c) => c.id == id);

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectionProvider);
    final spec = ref.watch(viewSpecProvider(column.sheetId));
    final columnSelected =
        selection is ColumnSelected && selection.columnId == column.id;
    final active = selection is CellSelected && selection.columnId == column.id;
    final sort = spec.query.sort;
    final sorted = sort?.columnId == column.id;
    final filtered = spec.query.activeFilters.containsKey(column.id);
    final color = active ? AppColors.accent : AppColors.textMuted;

    return DragTarget<ColumnDrag>(
      onWillAcceptWithDetails: (details) => details.data.id != column.id,
      onAcceptWithDetails: (details) => _move(details.data.id),
      builder: (context, candidates, _) {
        final dropping = candidates.isNotEmpty;
        // Le repère de dépôt est du côté où la colonne viendra se placer.
        final dropAfter =
            dropping && _indexOf(candidates.first!.id) < _indexOf(column.id);
        const dropSide = BorderSide(color: AppColors.accent, width: 3);
        return Container(
          width: widget.width,
          height: AppSizes.rowHeight,
          decoration: BoxDecoration(
            color: active ? AppColors.accentTint : AppColors.header,
            border: columnSelected
                ? Border.all(color: AppColors.accent, width: 2)
                : Border(
                    left: dropping && !dropAfter ? dropSide : BorderSide.none,
                    right: dropAfter
                        ? dropSide
                        : const BorderSide(color: AppColors.headerLine),
                    bottom: BorderSide(
                      width: active ? 2 : 1,
                      color: active ? AppColors.accent : AppColors.headerLine,
                    ),
                  ),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Draggable<ColumnDrag>(
                      data: ColumnDrag(column.id),
                      axis: Axis.horizontal,
                      feedback: _DragFeedback(label: column.label),
                      childWhenDragging: const Opacity(
                        opacity: 0.4,
                        child: SizedBox.expand(),
                      ),
                      child: Semantics(
                        button: true,
                        selected: columnSelected,
                        label: 'Sélectionner la colonne ${column.label}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onTap,
                          child: Row(
                            children: [
                              const SizedBox(width: 6),
                              Icon(column.type.icon, size: 14, color: color),
                              Expanded(
                                child: Text(
                                  column.label,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: active || columnSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (sorted)
                                Icon(
                                  sort!.ascending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 12,
                                  color: AppColors.accent,
                                  semanticLabel: 'Colonne triée',
                                ),
                              if (spec.groupBy == column.id)
                                const Icon(
                                  Icons.table_rows_outlined,
                                  size: 12,
                                  color: AppColors.accent,
                                  semanticLabel: 'Colonne de regroupement',
                                ),
                              if (filtered)
                                const Icon(
                                  Icons.filter_alt,
                                  size: 12,
                                  color: AppColors.accent,
                                  semanticLabel: 'Colonne filtrée',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Popover(
                    width: 300,
                    anchorBuilder: (context, toggle, isOpen) => Tooltip(
                      message: 'Options de la colonne ${column.label}',
                      child: InkWell(
                        onTap: toggle,
                        child: SizedBox(
                          width: 22,
                          height: AppSizes.rowHeight,
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    panelBuilder: (context, close) =>
                        ColumnMenu(column: column, close: close),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 8,
                child: Semantics(
                  container: true,
                  label: 'Régler la largeur de la colonne ${column.label}',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) =>
                          _dragStartWidth = widget.width,
                      onHorizontalDragUpdate: (details) {
                        final start = _dragStartWidth;
                        if (start == null) return;
                        _dragStartWidth = start + details.delta.dx;
                        ref
                            .read(columnResizeProvider.notifier)
                            .update(
                              column.id.value,
                              _dragStartWidth!
                                  .clamp(ColumnDef.minWidth, ColumnDef.maxWidth)
                                  .toDouble(),
                            );
                      },
                      onHorizontalDragEnd: (_) async {
                        final width = _dragStartWidth;
                        _dragStartWidth = null;
                        if (width != null) {
                          await ref
                              .read(workbookServiceProvider)
                              .resizeColumn(column, width);
                        }
                        ref.read(columnResizeProvider.notifier).end();
                      },
                      onDoubleTap: () => ref
                          .read(workbookServiceProvider)
                          .resizeColumn(column, ColumnDef.defaultWidth),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
