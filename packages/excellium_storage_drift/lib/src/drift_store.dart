import 'package:drift/drift.dart';
import 'package:excellium_core/excellium_core.dart';

import 'cell_codec.dart';
import 'database.dart';

/// Implémentation SQLite (Drift) du stockage d'Excellium.
final class DriftStore implements ExcelliumStore {
  /// Ouvre le stockage sur [executor] : un fichier sur l'appareil en
  /// production, une base en mémoire dans les tests.
  DriftStore(QueryExecutor executor) : _db = ExcelliumDatabase(executor) {
    sheets = _Sheets(_db);
    columns = _Columns(_db);
    rows = _Rows(_db);
    views = _Views(_db);
  }

  final ExcelliumDatabase _db;

  @override
  late final SheetRepository sheets;

  @override
  late final ColumnRepository columns;

  @override
  late final RowRepository rows;

  @override
  late final ViewRepository views;

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  @override
  Future<void> close() => _db.close();
}

final class _Sheets implements SheetRepository {
  _Sheets(this._db);

  final ExcelliumDatabase _db;

  SimpleSelectStatement<$SheetRecordsTable, SheetRecord> get _ordered =>
      _db.select(_db.sheetRecords)
        ..orderBy([(t) => OrderingTerm.asc(t.position)]);

  static Sheet _toSheet(SheetRecord record) => Sheet(
    id: SheetId(record.id),
    name: record.name,
    position: record.position,
  );

  @override
  Stream<List<Sheet>> watchSheets() =>
      _ordered.watch().map((records) => records.map(_toSheet).toList());

  @override
  Future<List<Sheet>> getSheets() async =>
      (await _ordered.get()).map(_toSheet).toList();

  @override
  Future<Sheet> createSheet({required String name}) {
    return _db.transaction(() async {
      final count = await _db.sheetRecords.count().getSingle();
      final sheet = Sheet(id: SheetId(newId()), name: name, position: count);
      await _db
          .into(_db.sheetRecords)
          .insert(
            SheetRecordsCompanion.insert(
              id: sheet.id.value,
              name: sheet.name,
              position: sheet.position,
            ),
          );
      return sheet;
    });
  }

  @override
  Future<void> renameSheet(SheetId id, String name) =>
      (_db.update(_db.sheetRecords)..where((t) => t.id.equals(id.value))).write(
        SheetRecordsCompanion(name: Value(name)),
      );

  @override
  Future<void> reorderSheets(List<SheetId> orderedIds) {
    return _db.transaction(() async {
      for (final (index, id) in orderedIds.indexed) {
        await (_db.update(_db.sheetRecords)
              ..where((t) => t.id.equals(id.value)))
            .write(SheetRecordsCompanion(position: Value(index)));
      }
    });
  }

  @override
  Future<void> deleteSheet(SheetId id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.sheetRecords,
      )..where((t) => t.id.equals(id.value))).go();
      final remaining = await _ordered.get();
      for (final (index, record) in remaining.indexed) {
        if (record.position == index) continue;
        await (_db.update(_db.sheetRecords)
              ..where((t) => t.id.equals(record.id)))
            .write(SheetRecordsCompanion(position: Value(index)));
      }
    });
  }
}

final class _Columns implements ColumnRepository {
  _Columns(this._db);

  final ExcelliumDatabase _db;

  SimpleSelectStatement<$ColumnRecordsTable, ColumnRecord> _ordered(
    SheetId sheetId,
  ) => _db.select(_db.columnRecords)
    ..where((t) => t.sheetId.equals(sheetId.value))
    ..orderBy([(t) => OrderingTerm.asc(t.position)]);

  static ColumnDef _toColumn(ColumnRecord record) {
    final type = decodeColumnType(record.type);
    final reference = record.reference;
    return ColumnDef(
      id: ColumnId(record.id),
      sheetId: SheetId(record.sheetId),
      position: record.position,
      name: record.name,
      type: type,
      width: record.width,
      reference: type == ColumnType.reference
          ? (reference == null
                ? const ReferenceConfig()
                : decodeReferenceConfig(reference))
          : null,
      style: decodeCellStyle(record.style),
      options: decodeOptions(record.options),
      formula: record.formula ?? '',
      groupCalc: record.groupCalc ?? '',
      calcCells: decodeCalcCells(record.calcCells),
    );
  }

  static String? _encodeReference(ColumnDef column) {
    if (column.type != ColumnType.reference) return null;
    return encodeReferenceConfig(column.reference ?? const ReferenceConfig());
  }

  @override
  Stream<List<ColumnDef>> watchColumns(SheetId sheetId) =>
      _ordered(sheetId)
          .watch()
          .map((records) => records.map(_toColumn).toList());

  @override
  Future<List<ColumnDef>> getColumns(SheetId sheetId) async =>
      (await _ordered(sheetId).get()).map(_toColumn).toList();

  @override
  Future<ColumnDef> addColumn(
    SheetId sheetId, {
    String name = '',
    ColumnType type = ColumnType.text,
  }) {
    return _db.transaction(() async {
      final count = await _db.columnRecords
          .count(where: (t) => t.sheetId.equals(sheetId.value))
          .getSingle();
      final column = ColumnDef(
        id: ColumnId(newId()),
        sheetId: sheetId,
        position: count,
        name: name,
        type: type,
        reference: type == ColumnType.reference
            ? const ReferenceConfig()
            : null,
      );
      await _db
          .into(_db.columnRecords)
          .insert(
            ColumnRecordsCompanion.insert(
              id: column.id.value,
              sheetId: sheetId.value,
              name: column.name,
              type: column.type.name,
              position: column.position,
              width: column.width,
              reference: Value(_encodeReference(column)),
            ),
          );
      return column;
    });
  }

  @override
  Future<void> updateColumn(ColumnDef column) =>
      (_db.update(
        _db.columnRecords,
      )..where((t) => t.id.equals(column.id.value))).write(
        ColumnRecordsCompanion(
          name: Value(column.name),
          type: Value(column.type.name),
          width: Value(column.width),
          reference: Value(_encodeReference(column)),
          style: Value(encodeCellStyle(column.style)),
          options: Value(encodeOptions(column.options)),
          formula: Value(column.formula.isEmpty ? null : column.formula),
          groupCalc: Value(column.groupCalc.isEmpty ? null : column.groupCalc),
          calcCells: Value(encodeCalcCells(column.calcCells)),
        ),
      );

  @override
  Future<void> reorderColumns(SheetId sheetId, List<ColumnId> orderedIds) {
    return _db.transaction(() async {
      for (final (index, id) in orderedIds.indexed) {
        await (_db.update(_db.columnRecords)..where(
              (t) => t.id.equals(id.value) & t.sheetId.equals(sheetId.value),
            ))
            .write(ColumnRecordsCompanion(position: Value(index)));
      }
    });
  }

  @override
  Future<void> deleteColumn(ColumnId id) {
    return _db.transaction(() async {
      final record = await (_db.select(
        _db.columnRecords,
      )..where((t) => t.id.equals(id.value))).getSingleOrNull();
      if (record == null) return;
      await (_db.delete(
        _db.columnRecords,
      )..where((t) => t.id.equals(id.value))).go();
      final remaining = await _ordered(SheetId(record.sheetId)).get();
      for (final (index, other) in remaining.indexed) {
        if (other.position == index) continue;
        await (_db.update(_db.columnRecords)
              ..where((t) => t.id.equals(other.id)))
            .write(ColumnRecordsCompanion(position: Value(index)));
      }
    });
  }
}

final class _Rows implements RowRepository {
  _Rows(this._db);

  final ExcelliumDatabase _db;

  /// Lignes de la feuille avec leurs cellules et leurs styles. Une ligne qui
  /// a plusieurs cellules et plusieurs styles revient en produit cartésien ;
  /// [_assemble] regroupe par clé, donc les doublons sont sans effet.
  JoinedSelectStatement<HasResultSet, dynamic> _joined(SheetId sheetId) =>
      _db.select(_db.rowRecords).join([
          leftOuterJoin(
            _db.cellRecords,
            _db.cellRecords.rowId.equalsExp(_db.rowRecords.id),
          ),
          leftOuterJoin(
            _db.cellStyleRecords,
            _db.cellStyleRecords.rowId.equalsExp(_db.rowRecords.id),
          ),
        ])
        ..where(_db.rowRecords.sheetId.equals(sheetId.value))
        ..orderBy([OrderingTerm.asc(_db.rowRecords.position)]);

  List<SheetRow> _assemble(List<TypedResult> results) {
    final order = <String>[];
    final records = <String, RowRecord>{};
    final cells = <String, Map<ColumnId, CellValue>>{};
    final styles = <String, Map<ColumnId, CellStyle>>{};
    for (final result in results) {
      final row = result.readTable(_db.rowRecords);
      if (!records.containsKey(row.id)) {
        order.add(row.id);
        records[row.id] = row;
        cells[row.id] = {};
        styles[row.id] = {};
      }
      final cell = result.readTableOrNull(_db.cellRecords);
      if (cell != null) {
        final value = decodeCellValue(cell.value);
        if (value != null) cells[row.id]![ColumnId(cell.columnId)] = value;
      }
      final styled = result.readTableOrNull(_db.cellStyleRecords);
      if (styled != null) {
        final style = decodeCellStyle(styled.style);
        if (!style.isEmpty) styles[row.id]![ColumnId(styled.columnId)] = style;
      }
    }
    return [
      for (final id in order)
        SheetRow(
          id: RowId(id),
          sheetId: SheetId(records[id]!.sheetId),
          position: records[id]!.position,
          height: records[id]!.height,
          cells: cells[id]!,
          styles: styles[id]!,
        ),
    ];
  }

  @override
  Stream<List<SheetRow>> watchRows(SheetId sheetId) =>
      _joined(sheetId).watch().map(_assemble);

  @override
  Future<List<SheetRow>> getRows(SheetId sheetId) async =>
      _assemble(await _joined(sheetId).get());

  @override
  Future<SheetRow> addRow(SheetId sheetId) {
    return _db.transaction(() async {
      final count = await _db.rowRecords
          .count(where: (t) => t.sheetId.equals(sheetId.value))
          .getSingle();
      final row = SheetRow(
        id: RowId(newId()),
        sheetId: sheetId,
        position: count,
      );
      await _db
          .into(_db.rowRecords)
          .insert(
            RowRecordsCompanion.insert(
              id: row.id.value,
              sheetId: sheetId.value,
              position: row.position,
            ),
          );
      return row;
    });
  }

  @override
  Future<void> setCell(RowId rowId, ColumnId columnId, CellValue? value) async {
    if (value == null) {
      await (_db.delete(_db.cellRecords)..where(
            (t) =>
                t.rowId.equals(rowId.value) & t.columnId.equals(columnId.value),
          ))
          .go();
      return;
    }
    await _db
        .into(_db.cellRecords)
        .insertOnConflictUpdate(
          CellRecordsCompanion.insert(
            rowId: rowId.value,
            columnId: columnId.value,
            value: encodeCellValue(value),
          ),
        );
  }

  @override
  Future<void> setCellStyle(
    RowId rowId,
    ColumnId columnId,
    CellStyle? style,
  ) async {
    final encoded = style == null ? null : encodeCellStyle(style);
    if (encoded == null) {
      await (_db.delete(_db.cellStyleRecords)..where(
            (t) =>
                t.rowId.equals(rowId.value) & t.columnId.equals(columnId.value),
          ))
          .go();
      return;
    }
    await _db
        .into(_db.cellStyleRecords)
        .insertOnConflictUpdate(
          CellStyleRecordsCompanion.insert(
            rowId: rowId.value,
            columnId: columnId.value,
            style: encoded,
          ),
        );
  }

  @override
  Future<void> setRowHeight(RowId rowId, double? height) =>
      (_db.update(_db.rowRecords)..where((t) => t.id.equals(rowId.value)))
          .write(RowRecordsCompanion(height: Value(height)));

  @override
  Future<void> deleteRow(RowId id) {
    return _db.transaction(() async {
      final record = await (_db.select(
        _db.rowRecords,
      )..where((t) => t.id.equals(id.value))).getSingleOrNull();
      if (record == null) return;
      await (_db.delete(
        _db.rowRecords,
      )..where((t) => t.id.equals(id.value))).go();
      final remaining =
          await (_db.select(_db.rowRecords)
                ..where((t) => t.sheetId.equals(record.sheetId))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      for (final (index, other) in remaining.indexed) {
        if (other.position == index) continue;
        await (_db.update(_db.rowRecords)..where((t) => t.id.equals(other.id)))
            .write(RowRecordsCompanion(position: Value(index)));
      }
    });
  }
}

final class _Views implements ViewRepository {
  _Views(this._db);

  final ExcelliumDatabase _db;

  SimpleSelectStatement<$ViewRecordsTable, ViewRecord> _ordered(
    SheetId sheetId,
  ) => _db.select(_db.viewRecords)
    ..where((t) => t.sheetId.equals(sheetId.value))
    ..orderBy([(t) => OrderingTerm.asc(t.position)]);

  static SavedView _toView(ViewRecord record) => SavedView(
    id: ViewId(record.id),
    sheetId: SheetId(record.sheetId),
    name: record.name,
    position: record.position,
    spec: decodeViewSpec(record.spec),
  );

  @override
  Stream<List<SavedView>> watchViews(SheetId sheetId) =>
      _ordered(sheetId).watch().map((records) => records.map(_toView).toList());

  @override
  Future<List<SavedView>> getViews(SheetId sheetId) async =>
      (await _ordered(sheetId).get()).map(_toView).toList();

  @override
  Future<SavedView> createView(
    SheetId sheetId, {
    required String name,
    required ViewSpec spec,
  }) {
    return _db.transaction(() async {
      final count = await _db.viewRecords
          .count(where: (t) => t.sheetId.equals(sheetId.value))
          .getSingle();
      final view = SavedView(
        id: ViewId(newId()),
        sheetId: sheetId,
        name: name,
        position: count,
        spec: spec,
      );
      await _db
          .into(_db.viewRecords)
          .insert(
            ViewRecordsCompanion.insert(
              id: view.id.value,
              sheetId: sheetId.value,
              name: name,
              position: count,
              spec: encodeViewSpec(spec),
            ),
          );
      return view;
    });
  }

  @override
  Future<void> updateView(SavedView view) =>
      (_db.update(
        _db.viewRecords,
      )..where((t) => t.id.equals(view.id.value))).write(
        ViewRecordsCompanion(
          name: Value(view.name),
          spec: Value(encodeViewSpec(view.spec)),
        ),
      );

  @override
  Future<void> deleteView(ViewId id) {
    return _db.transaction(() async {
      final record = await (_db.select(
        _db.viewRecords,
      )..where((t) => t.id.equals(id.value))).getSingleOrNull();
      if (record == null) return;
      await (_db.delete(
        _db.viewRecords,
      )..where((t) => t.id.equals(id.value))).go();
      final remaining = await _ordered(SheetId(record.sheetId)).get();
      for (final (index, other) in remaining.indexed) {
        if (other.position == index) continue;
        await (_db.update(_db.viewRecords)..where((t) => t.id.equals(other.id)))
            .write(ViewRecordsCompanion(position: Value(index)));
      }
    });
  }
}
