import 'dart:async';

import 'package:collection/collection.dart';

import '../model/cell_value.dart';
import '../model/column.dart';
import '../model/ids.dart';
import '../model/row.dart';
import '../model/sheet.dart';
import '../model/style.dart';
import '../model/view.dart';
import '../ports/store.dart';

/// Stockage en mémoire, sans persistance.
///
/// Sert aux tests et aux aperçus, et prouve que le cœur et l'interface ne
/// dépendent d'aucun moteur de stockage particulier.
final class InMemoryStore implements ExcelliumStore {
  InMemoryStore() {
    sheets = _Sheets(this);
    columns = _Columns(this);
    rows = _Rows(this);
    views = _Views(this);
  }

  @override
  late final SheetRepository sheets;

  @override
  late final ColumnRepository columns;

  @override
  late final RowRepository rows;

  @override
  late final ViewRepository views;

  final Map<ViewId, SavedView> _views = {};
  final Map<SheetId, Sheet> _sheets = {};
  final Map<ColumnId, ColumnDef> _columns = {};
  final Map<RowId, SheetRow> _rows = {};

  final StreamController<void> _changes = StreamController.broadcast();
  int _transactionDepth = 0;
  bool _dirty = false;

  void _notify() {
    if (_transactionDepth > 0) {
      _dirty = true;
    } else if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  /// Flux qui émet la lecture courante, puis une nouvelle à chaque changement.
  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((controller) {
    controller.add(read());
    final subscription = _changes.stream.listen(
      (_) => controller.add(read()),
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    final snapshot = _transactionDepth == 0
        ? (Map.of(_sheets), Map.of(_columns), Map.of(_rows), Map.of(_views))
        : null;
    _transactionDepth++;
    try {
      return await action();
    } catch (_) {
      if (snapshot != null) {
        _sheets
          ..clear()
          ..addAll(snapshot.$1);
        _columns
          ..clear()
          ..addAll(snapshot.$2);
        _rows
          ..clear()
          ..addAll(snapshot.$3);
        _views
          ..clear()
          ..addAll(snapshot.$4);
        _dirty = false;
      }
      rethrow;
    } finally {
      _transactionDepth--;
      if (_transactionDepth == 0 && _dirty) {
        _dirty = false;
        _notify();
      }
    }
  }

  @override
  Future<void> close() => _changes.close();

  List<Sheet> _sortedSheets() =>
      _sheets.values.sortedBy<num>((sheet) => sheet.position);

  List<ColumnDef> _sortedColumns(SheetId sheetId) => _columns.values
      .where((column) => column.sheetId == sheetId)
      .sortedBy<num>((column) => column.position);

  List<SheetRow> _sortedRows(SheetId sheetId) => _rows.values
      .where((row) => row.sheetId == sheetId)
      .sortedBy<num>((row) => row.position);

  List<SavedView> _sortedViews(SheetId sheetId) => _views.values
      .where((view) => view.sheetId == sheetId)
      .sortedBy<num>((view) => view.position);
}

final class _Sheets implements SheetRepository {
  _Sheets(this._store);

  final InMemoryStore _store;

  @override
  Stream<List<Sheet>> watchSheets() => _store._watch(_store._sortedSheets);

  @override
  Future<List<Sheet>> getSheets() async => _store._sortedSheets();

  @override
  Future<Sheet> createSheet({required String name}) async {
    final sheet = Sheet(
      id: SheetId(newId()),
      name: name,
      position: _store._sheets.length,
    );
    _store._sheets[sheet.id] = sheet;
    _store._notify();
    return sheet;
  }

  @override
  Future<void> renameSheet(SheetId id, String name) async {
    final sheet = _store._sheets[id];
    if (sheet == null) return;
    _store._sheets[id] = sheet.copyWith(name: name);
    _store._notify();
  }

  @override
  Future<void> reorderSheets(List<SheetId> orderedIds) async {
    for (final (index, id) in orderedIds.indexed) {
      final sheet = _store._sheets[id];
      if (sheet != null) _store._sheets[id] = sheet.copyWith(position: index);
    }
    _store._notify();
  }

  @override
  Future<void> deleteSheet(SheetId id) async {
    if (_store._sheets.remove(id) == null) return;
    _store._columns.removeWhere((_, column) => column.sheetId == id);
    _store._rows.removeWhere((_, row) => row.sheetId == id);
    _store._views.removeWhere((_, view) => view.sheetId == id);
    for (final (index, sheet) in _store._sortedSheets().indexed) {
      _store._sheets[sheet.id] = sheet.copyWith(position: index);
    }
    _store._notify();
  }
}

final class _Columns implements ColumnRepository {
  _Columns(this._store);

  final InMemoryStore _store;

  @override
  Stream<List<ColumnDef>> watchColumns(SheetId sheetId) =>
      _store._watch(() => _store._sortedColumns(sheetId));

  @override
  Future<List<ColumnDef>> getColumns(SheetId sheetId) async =>
      _store._sortedColumns(sheetId);

  @override
  Future<ColumnDef> addColumn(
    SheetId sheetId, {
    String name = '',
    ColumnType type = ColumnType.text,
  }) async {
    final column = ColumnDef(
      id: ColumnId(newId()),
      sheetId: sheetId,
      position: _store._sortedColumns(sheetId).length,
      name: name,
      type: type,
      reference: type == ColumnType.reference ? const ReferenceConfig() : null,
    );
    _store._columns[column.id] = column;
    _store._notify();
    return column;
  }

  @override
  Future<void> updateColumn(ColumnDef column) async {
    final current = _store._columns[column.id];
    if (current == null) return;
    _store._columns[column.id] = column.copyWith(position: current.position);
    _store._notify();
  }

  @override
  Future<void> reorderColumns(
    SheetId sheetId,
    List<ColumnId> orderedIds,
  ) async {
    for (final (index, id) in orderedIds.indexed) {
      final column = _store._columns[id];
      if (column != null && column.sheetId == sheetId) {
        _store._columns[id] = column.copyWith(position: index);
      }
    }
    _store._notify();
  }

  @override
  Future<void> deleteColumn(ColumnId id) async {
    final column = _store._columns.remove(id);
    if (column == null) return;
    for (final row in _store._sortedRows(column.sheetId)) {
      if (row[id] != null || row.styles[id] != null) {
        _store._rows[row.id] = row.withCell(id, null).withStyle(id, null);
      }
    }
    for (final (index, other)
        in _store._sortedColumns(column.sheetId).indexed) {
      _store._columns[other.id] = other.copyWith(position: index);
    }
    _store._notify();
  }
}

final class _Rows implements RowRepository {
  _Rows(this._store);

  final InMemoryStore _store;

  @override
  Stream<List<SheetRow>> watchRows(SheetId sheetId) =>
      _store._watch(() => _store._sortedRows(sheetId));

  @override
  Future<List<SheetRow>> getRows(SheetId sheetId) async =>
      _store._sortedRows(sheetId);

  @override
  Future<SheetRow> addRow(SheetId sheetId) async {
    final row = SheetRow(
      id: RowId(newId()),
      sheetId: sheetId,
      position: _store._sortedRows(sheetId).length,
    );
    _store._rows[row.id] = row;
    _store._notify();
    return row;
  }

  @override
  Future<void> setCell(RowId rowId, ColumnId columnId, CellValue? value) async {
    final row = _store._rows[rowId];
    if (row == null) return;
    _store._rows[rowId] = row.withCell(columnId, value);
    _store._notify();
  }

  @override
  Future<void> setCellStyle(
    RowId rowId,
    ColumnId columnId,
    CellStyle? style,
  ) async {
    final row = _store._rows[rowId];
    if (row == null) return;
    _store._rows[rowId] = row.withStyle(columnId, style);
    _store._notify();
  }

  @override
  Future<void> setRowHeight(RowId rowId, double? height) async {
    final row = _store._rows[rowId];
    if (row == null) return;
    _store._rows[rowId] = row.copyWith(
      height: height,
      clearHeight: height == null,
    );
    _store._notify();
  }

  @override
  Future<void> deleteRow(RowId id) async {
    final row = _store._rows.remove(id);
    if (row == null) return;
    for (final (index, other) in _store._sortedRows(row.sheetId).indexed) {
      _store._rows[other.id] = other.copyWith(position: index);
    }
    _store._notify();
  }
}

final class _Views implements ViewRepository {
  _Views(this._store);

  final InMemoryStore _store;

  @override
  Stream<List<SavedView>> watchViews(SheetId sheetId) =>
      _store._watch(() => _store._sortedViews(sheetId));

  @override
  Future<List<SavedView>> getViews(SheetId sheetId) async =>
      _store._sortedViews(sheetId);

  @override
  Future<SavedView> createView(
    SheetId sheetId, {
    required String name,
    required ViewSpec spec,
  }) async {
    final view = SavedView(
      id: ViewId(newId()),
      sheetId: sheetId,
      name: name,
      position: _store._sortedViews(sheetId).length,
      spec: spec,
    );
    _store._views[view.id] = view;
    _store._notify();
    return view;
  }

  @override
  Future<void> deleteView(ViewId id) async {
    final view = _store._views.remove(id);
    if (view == null) return;
    for (final (index, other) in _store._sortedViews(view.sheetId).indexed) {
      _store._views[other.id] = SavedView(
        id: other.id,
        sheetId: other.sheetId,
        name: other.name,
        position: index,
        spec: other.spec,
      );
    }
    _store._notify();
  }
}
