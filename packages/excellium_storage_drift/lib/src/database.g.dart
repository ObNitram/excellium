// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SheetRecordsTable extends SheetRecords
    with TableInfo<$SheetRecordsTable, SheetRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SheetRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sheets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SheetRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SheetRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SheetRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SheetRecordsTable createAlias(String alias) {
    return $SheetRecordsTable(attachedDatabase, alias);
  }
}

class SheetRecord extends DataClass implements Insertable<SheetRecord> {
  final String id;
  final String name;
  final int position;
  const SheetRecord({
    required this.id,
    required this.name,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    return map;
  }

  SheetRecordsCompanion toCompanion(bool nullToAbsent) {
    return SheetRecordsCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
    );
  }

  factory SheetRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SheetRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  SheetRecord copyWith({String? id, String? name, int? position}) =>
      SheetRecord(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
      );
  SheetRecord copyWithCompanion(SheetRecordsCompanion data) {
    return SheetRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SheetRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position);
}

class SheetRecordsCompanion extends UpdateCompanion<SheetRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> position;
  final Value<int> rowid;
  const SheetRecordsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SheetRecordsCompanion.insert({
    required String id,
    required String name,
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position);
  static Insertable<SheetRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SheetRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return SheetRecordsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SheetRecordsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ColumnRecordsTable extends ColumnRecords
    with TableInfo<$ColumnRecordsTable, ColumnRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ColumnRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sheetIdMeta = const VerificationMeta(
    'sheetId',
  );
  @override
  late final GeneratedColumn<String> sheetId = GeneratedColumn<String>(
    'sheet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sheets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formulaMeta = const VerificationMeta(
    'formula',
  );
  @override
  late final GeneratedColumn<String> formula = GeneratedColumn<String>(
    'formula',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupCalcMeta = const VerificationMeta(
    'groupCalc',
  );
  @override
  late final GeneratedColumn<String> groupCalc = GeneratedColumn<String>(
    'group_calc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calcCellsMeta = const VerificationMeta(
    'calcCells',
  );
  @override
  late final GeneratedColumn<String> calcCells = GeneratedColumn<String>(
    'calc_cells',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sheetId,
    name,
    type,
    position,
    width,
    reference,
    style,
    options,
    formula,
    groupCalc,
    calcCells,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'columns';
  @override
  VerificationContext validateIntegrity(
    Insertable<ColumnRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sheet_id')) {
      context.handle(
        _sheetIdMeta,
        sheetId.isAcceptableOrUnknown(data['sheet_id']!, _sheetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sheetIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    }
    if (data.containsKey('formula')) {
      context.handle(
        _formulaMeta,
        formula.isAcceptableOrUnknown(data['formula']!, _formulaMeta),
      );
    }
    if (data.containsKey('group_calc')) {
      context.handle(
        _groupCalcMeta,
        groupCalc.isAcceptableOrUnknown(data['group_calc']!, _groupCalcMeta),
      );
    }
    if (data.containsKey('calc_cells')) {
      context.handle(
        _calcCellsMeta,
        calcCells.isAcceptableOrUnknown(data['calc_cells']!, _calcCellsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ColumnRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ColumnRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      ),
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      ),
      formula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula'],
      ),
      groupCalc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_calc'],
      ),
      calcCells: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calc_cells'],
      ),
    );
  }

  @override
  $ColumnRecordsTable createAlias(String alias) {
    return $ColumnRecordsTable(attachedDatabase, alias);
  }
}

class ColumnRecord extends DataClass implements Insertable<ColumnRecord> {
  final String id;
  final String sheetId;
  final String name;
  final String type;
  final int position;
  final double width;

  /// Paramètres d'une colonne Référence, en JSON ; `null` pour les autres.
  final String? reference;

  /// Style de la colonne, en JSON ; `null` s'il n'y en a pas.
  final String? style;

  /// Catégories définies, en JSON ; `null` s'il n'y en a pas.
  final String? options;

  /// Formule d'une colonne Formule ; `null` s'il n'y en a pas.
  final String? formula;

  /// Contenu de la case de la colonne sur les lignes de regroupement.
  final String? groupCalc;

  /// Cases de calcul sous la colonne, en JSON (numéro de ligne → contenu).
  final String? calcCells;
  const ColumnRecord({
    required this.id,
    required this.sheetId,
    required this.name,
    required this.type,
    required this.position,
    required this.width,
    this.reference,
    this.style,
    this.options,
    this.formula,
    this.groupCalc,
    this.calcCells,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sheet_id'] = Variable<String>(sheetId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['position'] = Variable<int>(position);
    map['width'] = Variable<double>(width);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || style != null) {
      map['style'] = Variable<String>(style);
    }
    if (!nullToAbsent || options != null) {
      map['options'] = Variable<String>(options);
    }
    if (!nullToAbsent || formula != null) {
      map['formula'] = Variable<String>(formula);
    }
    if (!nullToAbsent || groupCalc != null) {
      map['group_calc'] = Variable<String>(groupCalc);
    }
    if (!nullToAbsent || calcCells != null) {
      map['calc_cells'] = Variable<String>(calcCells);
    }
    return map;
  }

  ColumnRecordsCompanion toCompanion(bool nullToAbsent) {
    return ColumnRecordsCompanion(
      id: Value(id),
      sheetId: Value(sheetId),
      name: Value(name),
      type: Value(type),
      position: Value(position),
      width: Value(width),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      style: style == null && nullToAbsent
          ? const Value.absent()
          : Value(style),
      options: options == null && nullToAbsent
          ? const Value.absent()
          : Value(options),
      formula: formula == null && nullToAbsent
          ? const Value.absent()
          : Value(formula),
      groupCalc: groupCalc == null && nullToAbsent
          ? const Value.absent()
          : Value(groupCalc),
      calcCells: calcCells == null && nullToAbsent
          ? const Value.absent()
          : Value(calcCells),
    );
  }

  factory ColumnRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ColumnRecord(
      id: serializer.fromJson<String>(json['id']),
      sheetId: serializer.fromJson<String>(json['sheetId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      position: serializer.fromJson<int>(json['position']),
      width: serializer.fromJson<double>(json['width']),
      reference: serializer.fromJson<String?>(json['reference']),
      style: serializer.fromJson<String?>(json['style']),
      options: serializer.fromJson<String?>(json['options']),
      formula: serializer.fromJson<String?>(json['formula']),
      groupCalc: serializer.fromJson<String?>(json['groupCalc']),
      calcCells: serializer.fromJson<String?>(json['calcCells']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sheetId': serializer.toJson<String>(sheetId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'position': serializer.toJson<int>(position),
      'width': serializer.toJson<double>(width),
      'reference': serializer.toJson<String?>(reference),
      'style': serializer.toJson<String?>(style),
      'options': serializer.toJson<String?>(options),
      'formula': serializer.toJson<String?>(formula),
      'groupCalc': serializer.toJson<String?>(groupCalc),
      'calcCells': serializer.toJson<String?>(calcCells),
    };
  }

  ColumnRecord copyWith({
    String? id,
    String? sheetId,
    String? name,
    String? type,
    int? position,
    double? width,
    Value<String?> reference = const Value.absent(),
    Value<String?> style = const Value.absent(),
    Value<String?> options = const Value.absent(),
    Value<String?> formula = const Value.absent(),
    Value<String?> groupCalc = const Value.absent(),
    Value<String?> calcCells = const Value.absent(),
  }) => ColumnRecord(
    id: id ?? this.id,
    sheetId: sheetId ?? this.sheetId,
    name: name ?? this.name,
    type: type ?? this.type,
    position: position ?? this.position,
    width: width ?? this.width,
    reference: reference.present ? reference.value : this.reference,
    style: style.present ? style.value : this.style,
    options: options.present ? options.value : this.options,
    formula: formula.present ? formula.value : this.formula,
    groupCalc: groupCalc.present ? groupCalc.value : this.groupCalc,
    calcCells: calcCells.present ? calcCells.value : this.calcCells,
  );
  ColumnRecord copyWithCompanion(ColumnRecordsCompanion data) {
    return ColumnRecord(
      id: data.id.present ? data.id.value : this.id,
      sheetId: data.sheetId.present ? data.sheetId.value : this.sheetId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      position: data.position.present ? data.position.value : this.position,
      width: data.width.present ? data.width.value : this.width,
      reference: data.reference.present ? data.reference.value : this.reference,
      style: data.style.present ? data.style.value : this.style,
      options: data.options.present ? data.options.value : this.options,
      formula: data.formula.present ? data.formula.value : this.formula,
      groupCalc: data.groupCalc.present ? data.groupCalc.value : this.groupCalc,
      calcCells: data.calcCells.present ? data.calcCells.value : this.calcCells,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ColumnRecord(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('position: $position, ')
          ..write('width: $width, ')
          ..write('reference: $reference, ')
          ..write('style: $style, ')
          ..write('options: $options, ')
          ..write('formula: $formula, ')
          ..write('groupCalc: $groupCalc, ')
          ..write('calcCells: $calcCells')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sheetId,
    name,
    type,
    position,
    width,
    reference,
    style,
    options,
    formula,
    groupCalc,
    calcCells,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ColumnRecord &&
          other.id == this.id &&
          other.sheetId == this.sheetId &&
          other.name == this.name &&
          other.type == this.type &&
          other.position == this.position &&
          other.width == this.width &&
          other.reference == this.reference &&
          other.style == this.style &&
          other.options == this.options &&
          other.formula == this.formula &&
          other.groupCalc == this.groupCalc &&
          other.calcCells == this.calcCells);
}

class ColumnRecordsCompanion extends UpdateCompanion<ColumnRecord> {
  final Value<String> id;
  final Value<String> sheetId;
  final Value<String> name;
  final Value<String> type;
  final Value<int> position;
  final Value<double> width;
  final Value<String?> reference;
  final Value<String?> style;
  final Value<String?> options;
  final Value<String?> formula;
  final Value<String?> groupCalc;
  final Value<String?> calcCells;
  final Value<int> rowid;
  const ColumnRecordsCompanion({
    this.id = const Value.absent(),
    this.sheetId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.position = const Value.absent(),
    this.width = const Value.absent(),
    this.reference = const Value.absent(),
    this.style = const Value.absent(),
    this.options = const Value.absent(),
    this.formula = const Value.absent(),
    this.groupCalc = const Value.absent(),
    this.calcCells = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ColumnRecordsCompanion.insert({
    required String id,
    required String sheetId,
    required String name,
    required String type,
    required int position,
    required double width,
    this.reference = const Value.absent(),
    this.style = const Value.absent(),
    this.options = const Value.absent(),
    this.formula = const Value.absent(),
    this.groupCalc = const Value.absent(),
    this.calcCells = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sheetId = Value(sheetId),
       name = Value(name),
       type = Value(type),
       position = Value(position),
       width = Value(width);
  static Insertable<ColumnRecord> custom({
    Expression<String>? id,
    Expression<String>? sheetId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? position,
    Expression<double>? width,
    Expression<String>? reference,
    Expression<String>? style,
    Expression<String>? options,
    Expression<String>? formula,
    Expression<String>? groupCalc,
    Expression<String>? calcCells,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sheetId != null) 'sheet_id': sheetId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (position != null) 'position': position,
      if (width != null) 'width': width,
      if (reference != null) 'reference': reference,
      if (style != null) 'style': style,
      if (options != null) 'options': options,
      if (formula != null) 'formula': formula,
      if (groupCalc != null) 'group_calc': groupCalc,
      if (calcCells != null) 'calc_cells': calcCells,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ColumnRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? sheetId,
    Value<String>? name,
    Value<String>? type,
    Value<int>? position,
    Value<double>? width,
    Value<String?>? reference,
    Value<String?>? style,
    Value<String?>? options,
    Value<String?>? formula,
    Value<String?>? groupCalc,
    Value<String?>? calcCells,
    Value<int>? rowid,
  }) {
    return ColumnRecordsCompanion(
      id: id ?? this.id,
      sheetId: sheetId ?? this.sheetId,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      width: width ?? this.width,
      reference: reference ?? this.reference,
      style: style ?? this.style,
      options: options ?? this.options,
      formula: formula ?? this.formula,
      groupCalc: groupCalc ?? this.groupCalc,
      calcCells: calcCells ?? this.calcCells,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sheetId.present) {
      map['sheet_id'] = Variable<String>(sheetId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (formula.present) {
      map['formula'] = Variable<String>(formula.value);
    }
    if (groupCalc.present) {
      map['group_calc'] = Variable<String>(groupCalc.value);
    }
    if (calcCells.present) {
      map['calc_cells'] = Variable<String>(calcCells.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ColumnRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('position: $position, ')
          ..write('width: $width, ')
          ..write('reference: $reference, ')
          ..write('style: $style, ')
          ..write('options: $options, ')
          ..write('formula: $formula, ')
          ..write('groupCalc: $groupCalc, ')
          ..write('calcCells: $calcCells, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RowRecordsTable extends RowRecords
    with TableInfo<$RowRecordsTable, RowRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RowRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sheetIdMeta = const VerificationMeta(
    'sheetId',
  );
  @override
  late final GeneratedColumn<String> sheetId = GeneratedColumn<String>(
    'sheet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sheets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sheetId, position, height];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RowRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sheet_id')) {
      context.handle(
        _sheetIdMeta,
        sheetId.isAcceptableOrUnknown(data['sheet_id']!, _sheetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sheetIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RowRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RowRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      ),
    );
  }

  @override
  $RowRecordsTable createAlias(String alias) {
    return $RowRecordsTable(attachedDatabase, alias);
  }
}

class RowRecord extends DataClass implements Insertable<RowRecord> {
  final String id;
  final String sheetId;
  final int position;

  /// Hauteur choisie ; `null` pour la hauteur par défaut.
  final double? height;
  const RowRecord({
    required this.id,
    required this.sheetId,
    required this.position,
    this.height,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sheet_id'] = Variable<String>(sheetId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<double>(height);
    }
    return map;
  }

  RowRecordsCompanion toCompanion(bool nullToAbsent) {
    return RowRecordsCompanion(
      id: Value(id),
      sheetId: Value(sheetId),
      position: Value(position),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
    );
  }

  factory RowRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RowRecord(
      id: serializer.fromJson<String>(json['id']),
      sheetId: serializer.fromJson<String>(json['sheetId']),
      position: serializer.fromJson<int>(json['position']),
      height: serializer.fromJson<double?>(json['height']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sheetId': serializer.toJson<String>(sheetId),
      'position': serializer.toJson<int>(position),
      'height': serializer.toJson<double?>(height),
    };
  }

  RowRecord copyWith({
    String? id,
    String? sheetId,
    int? position,
    Value<double?> height = const Value.absent(),
  }) => RowRecord(
    id: id ?? this.id,
    sheetId: sheetId ?? this.sheetId,
    position: position ?? this.position,
    height: height.present ? height.value : this.height,
  );
  RowRecord copyWithCompanion(RowRecordsCompanion data) {
    return RowRecord(
      id: data.id.present ? data.id.value : this.id,
      sheetId: data.sheetId.present ? data.sheetId.value : this.sheetId,
      position: data.position.present ? data.position.value : this.position,
      height: data.height.present ? data.height.value : this.height,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RowRecord(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('position: $position, ')
          ..write('height: $height')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sheetId, position, height);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RowRecord &&
          other.id == this.id &&
          other.sheetId == this.sheetId &&
          other.position == this.position &&
          other.height == this.height);
}

class RowRecordsCompanion extends UpdateCompanion<RowRecord> {
  final Value<String> id;
  final Value<String> sheetId;
  final Value<int> position;
  final Value<double?> height;
  final Value<int> rowid;
  const RowRecordsCompanion({
    this.id = const Value.absent(),
    this.sheetId = const Value.absent(),
    this.position = const Value.absent(),
    this.height = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RowRecordsCompanion.insert({
    required String id,
    required String sheetId,
    required int position,
    this.height = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sheetId = Value(sheetId),
       position = Value(position);
  static Insertable<RowRecord> custom({
    Expression<String>? id,
    Expression<String>? sheetId,
    Expression<int>? position,
    Expression<double>? height,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sheetId != null) 'sheet_id': sheetId,
      if (position != null) 'position': position,
      if (height != null) 'height': height,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RowRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? sheetId,
    Value<int>? position,
    Value<double?>? height,
    Value<int>? rowid,
  }) {
    return RowRecordsCompanion(
      id: id ?? this.id,
      sheetId: sheetId ?? this.sheetId,
      position: position ?? this.position,
      height: height ?? this.height,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sheetId.present) {
      map['sheet_id'] = Variable<String>(sheetId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RowRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('position: $position, ')
          ..write('height: $height, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CellRecordsTable extends CellRecords
    with TableInfo<$CellRecordsTable, CellRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CellRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "rows" (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _columnIdMeta = const VerificationMeta(
    'columnId',
  );
  @override
  late final GeneratedColumn<String> columnId = GeneratedColumn<String>(
    'column_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES columns (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, columnId, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cells';
  @override
  VerificationContext validateIntegrity(
    Insertable<CellRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('column_id')) {
      context.handle(
        _columnIdMeta,
        columnId.isAcceptableOrUnknown(data['column_id']!, _columnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_columnIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId, columnId};
  @override
  CellRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CellRecord(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      columnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}column_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $CellRecordsTable createAlias(String alias) {
    return $CellRecordsTable(attachedDatabase, alias);
  }
}

class CellRecord extends DataClass implements Insertable<CellRecord> {
  final String rowId;
  final String columnId;

  /// Valeur typée, en JSON (voir `cell_codec.dart`).
  final String value;
  const CellRecord({
    required this.rowId,
    required this.columnId,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<String>(rowId);
    map['column_id'] = Variable<String>(columnId);
    map['value'] = Variable<String>(value);
    return map;
  }

  CellRecordsCompanion toCompanion(bool nullToAbsent) {
    return CellRecordsCompanion(
      rowId: Value(rowId),
      columnId: Value(columnId),
      value: Value(value),
    );
  }

  factory CellRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CellRecord(
      rowId: serializer.fromJson<String>(json['rowId']),
      columnId: serializer.fromJson<String>(json['columnId']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<String>(rowId),
      'columnId': serializer.toJson<String>(columnId),
      'value': serializer.toJson<String>(value),
    };
  }

  CellRecord copyWith({String? rowId, String? columnId, String? value}) =>
      CellRecord(
        rowId: rowId ?? this.rowId,
        columnId: columnId ?? this.columnId,
        value: value ?? this.value,
      );
  CellRecord copyWithCompanion(CellRecordsCompanion data) {
    return CellRecord(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      columnId: data.columnId.present ? data.columnId.value : this.columnId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CellRecord(')
          ..write('rowId: $rowId, ')
          ..write('columnId: $columnId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, columnId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CellRecord &&
          other.rowId == this.rowId &&
          other.columnId == this.columnId &&
          other.value == this.value);
}

class CellRecordsCompanion extends UpdateCompanion<CellRecord> {
  final Value<String> rowId;
  final Value<String> columnId;
  final Value<String> value;
  final Value<int> rowid;
  const CellRecordsCompanion({
    this.rowId = const Value.absent(),
    this.columnId = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CellRecordsCompanion.insert({
    required String rowId,
    required String columnId,
    required String value,
    this.rowid = const Value.absent(),
  }) : rowId = Value(rowId),
       columnId = Value(columnId),
       value = Value(value);
  static Insertable<CellRecord> custom({
    Expression<String>? rowId,
    Expression<String>? columnId,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (columnId != null) 'column_id': columnId,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CellRecordsCompanion copyWith({
    Value<String>? rowId,
    Value<String>? columnId,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return CellRecordsCompanion(
      rowId: rowId ?? this.rowId,
      columnId: columnId ?? this.columnId,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (columnId.present) {
      map['column_id'] = Variable<String>(columnId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CellRecordsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('columnId: $columnId, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CellStyleRecordsTable extends CellStyleRecords
    with TableInfo<$CellStyleRecordsTable, CellStyleRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CellStyleRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "rows" (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _columnIdMeta = const VerificationMeta(
    'columnId',
  );
  @override
  late final GeneratedColumn<String> columnId = GeneratedColumn<String>(
    'column_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES columns (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, columnId, style];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cell_styles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CellStyleRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('column_id')) {
      context.handle(
        _columnIdMeta,
        columnId.isAcceptableOrUnknown(data['column_id']!, _columnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_columnIdMeta);
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId, columnId};
  @override
  CellStyleRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CellStyleRecord(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      columnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}column_id'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
    );
  }

  @override
  $CellStyleRecordsTable createAlias(String alias) {
    return $CellStyleRecordsTable(attachedDatabase, alias);
  }
}

class CellStyleRecord extends DataClass implements Insertable<CellStyleRecord> {
  final String rowId;
  final String columnId;
  final String style;
  const CellStyleRecord({
    required this.rowId,
    required this.columnId,
    required this.style,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<String>(rowId);
    map['column_id'] = Variable<String>(columnId);
    map['style'] = Variable<String>(style);
    return map;
  }

  CellStyleRecordsCompanion toCompanion(bool nullToAbsent) {
    return CellStyleRecordsCompanion(
      rowId: Value(rowId),
      columnId: Value(columnId),
      style: Value(style),
    );
  }

  factory CellStyleRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CellStyleRecord(
      rowId: serializer.fromJson<String>(json['rowId']),
      columnId: serializer.fromJson<String>(json['columnId']),
      style: serializer.fromJson<String>(json['style']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<String>(rowId),
      'columnId': serializer.toJson<String>(columnId),
      'style': serializer.toJson<String>(style),
    };
  }

  CellStyleRecord copyWith({String? rowId, String? columnId, String? style}) =>
      CellStyleRecord(
        rowId: rowId ?? this.rowId,
        columnId: columnId ?? this.columnId,
        style: style ?? this.style,
      );
  CellStyleRecord copyWithCompanion(CellStyleRecordsCompanion data) {
    return CellStyleRecord(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      columnId: data.columnId.present ? data.columnId.value : this.columnId,
      style: data.style.present ? data.style.value : this.style,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CellStyleRecord(')
          ..write('rowId: $rowId, ')
          ..write('columnId: $columnId, ')
          ..write('style: $style')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, columnId, style);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CellStyleRecord &&
          other.rowId == this.rowId &&
          other.columnId == this.columnId &&
          other.style == this.style);
}

class CellStyleRecordsCompanion extends UpdateCompanion<CellStyleRecord> {
  final Value<String> rowId;
  final Value<String> columnId;
  final Value<String> style;
  final Value<int> rowid;
  const CellStyleRecordsCompanion({
    this.rowId = const Value.absent(),
    this.columnId = const Value.absent(),
    this.style = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CellStyleRecordsCompanion.insert({
    required String rowId,
    required String columnId,
    required String style,
    this.rowid = const Value.absent(),
  }) : rowId = Value(rowId),
       columnId = Value(columnId),
       style = Value(style);
  static Insertable<CellStyleRecord> custom({
    Expression<String>? rowId,
    Expression<String>? columnId,
    Expression<String>? style,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (columnId != null) 'column_id': columnId,
      if (style != null) 'style': style,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CellStyleRecordsCompanion copyWith({
    Value<String>? rowId,
    Value<String>? columnId,
    Value<String>? style,
    Value<int>? rowid,
  }) {
    return CellStyleRecordsCompanion(
      rowId: rowId ?? this.rowId,
      columnId: columnId ?? this.columnId,
      style: style ?? this.style,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (columnId.present) {
      map['column_id'] = Variable<String>(columnId.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CellStyleRecordsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('columnId: $columnId, ')
          ..write('style: $style, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ViewRecordsTable extends ViewRecords
    with TableInfo<$ViewRecordsTable, ViewRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ViewRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sheetIdMeta = const VerificationMeta(
    'sheetId',
  );
  @override
  late final GeneratedColumn<String> sheetId = GeneratedColumn<String>(
    'sheet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sheets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specMeta = const VerificationMeta('spec');
  @override
  late final GeneratedColumn<String> spec = GeneratedColumn<String>(
    'spec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sheetId, name, position, spec];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'views';
  @override
  VerificationContext validateIntegrity(
    Insertable<ViewRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sheet_id')) {
      context.handle(
        _sheetIdMeta,
        sheetId.isAcceptableOrUnknown(data['sheet_id']!, _sheetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sheetIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('spec')) {
      context.handle(
        _specMeta,
        spec.isAcceptableOrUnknown(data['spec']!, _specMeta),
      );
    } else if (isInserting) {
      context.missing(_specMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ViewRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ViewRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      spec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec'],
      )!,
    );
  }

  @override
  $ViewRecordsTable createAlias(String alias) {
    return $ViewRecordsTable(attachedDatabase, alias);
  }
}

class ViewRecord extends DataClass implements Insertable<ViewRecord> {
  final String id;
  final String sheetId;
  final String name;
  final int position;

  /// Affichage, tri, filtres et colonnes masquées, en JSON.
  final String spec;
  const ViewRecord({
    required this.id,
    required this.sheetId,
    required this.name,
    required this.position,
    required this.spec,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sheet_id'] = Variable<String>(sheetId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['spec'] = Variable<String>(spec);
    return map;
  }

  ViewRecordsCompanion toCompanion(bool nullToAbsent) {
    return ViewRecordsCompanion(
      id: Value(id),
      sheetId: Value(sheetId),
      name: Value(name),
      position: Value(position),
      spec: Value(spec),
    );
  }

  factory ViewRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ViewRecord(
      id: serializer.fromJson<String>(json['id']),
      sheetId: serializer.fromJson<String>(json['sheetId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      spec: serializer.fromJson<String>(json['spec']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sheetId': serializer.toJson<String>(sheetId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'spec': serializer.toJson<String>(spec),
    };
  }

  ViewRecord copyWith({
    String? id,
    String? sheetId,
    String? name,
    int? position,
    String? spec,
  }) => ViewRecord(
    id: id ?? this.id,
    sheetId: sheetId ?? this.sheetId,
    name: name ?? this.name,
    position: position ?? this.position,
    spec: spec ?? this.spec,
  );
  ViewRecord copyWithCompanion(ViewRecordsCompanion data) {
    return ViewRecord(
      id: data.id.present ? data.id.value : this.id,
      sheetId: data.sheetId.present ? data.sheetId.value : this.sheetId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      spec: data.spec.present ? data.spec.value : this.spec,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ViewRecord(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('spec: $spec')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sheetId, name, position, spec);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewRecord &&
          other.id == this.id &&
          other.sheetId == this.sheetId &&
          other.name == this.name &&
          other.position == this.position &&
          other.spec == this.spec);
}

class ViewRecordsCompanion extends UpdateCompanion<ViewRecord> {
  final Value<String> id;
  final Value<String> sheetId;
  final Value<String> name;
  final Value<int> position;
  final Value<String> spec;
  final Value<int> rowid;
  const ViewRecordsCompanion({
    this.id = const Value.absent(),
    this.sheetId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.spec = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ViewRecordsCompanion.insert({
    required String id,
    required String sheetId,
    required String name,
    required int position,
    required String spec,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sheetId = Value(sheetId),
       name = Value(name),
       position = Value(position),
       spec = Value(spec);
  static Insertable<ViewRecord> custom({
    Expression<String>? id,
    Expression<String>? sheetId,
    Expression<String>? name,
    Expression<int>? position,
    Expression<String>? spec,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sheetId != null) 'sheet_id': sheetId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (spec != null) 'spec': spec,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ViewRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? sheetId,
    Value<String>? name,
    Value<int>? position,
    Value<String>? spec,
    Value<int>? rowid,
  }) {
    return ViewRecordsCompanion(
      id: id ?? this.id,
      sheetId: sheetId ?? this.sheetId,
      name: name ?? this.name,
      position: position ?? this.position,
      spec: spec ?? this.spec,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sheetId.present) {
      map['sheet_id'] = Variable<String>(sheetId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (spec.present) {
      map['spec'] = Variable<String>(spec.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ViewRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sheetId: $sheetId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('spec: $spec, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ExcelliumDatabase extends GeneratedDatabase {
  _$ExcelliumDatabase(QueryExecutor e) : super(e);
  $ExcelliumDatabaseManager get managers => $ExcelliumDatabaseManager(this);
  late final $SheetRecordsTable sheetRecords = $SheetRecordsTable(this);
  late final $ColumnRecordsTable columnRecords = $ColumnRecordsTable(this);
  late final $RowRecordsTable rowRecords = $RowRecordsTable(this);
  late final $CellRecordsTable cellRecords = $CellRecordsTable(this);
  late final $CellStyleRecordsTable cellStyleRecords = $CellStyleRecordsTable(
    this,
  );
  late final $ViewRecordsTable viewRecords = $ViewRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sheetRecords,
    columnRecords,
    rowRecords,
    cellRecords,
    cellStyleRecords,
    viewRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sheets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('columns', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sheets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cells', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'columns',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cells', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cell_styles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'columns',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cell_styles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sheets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('views', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SheetRecordsTableCreateCompanionBuilder =
    SheetRecordsCompanion Function({
      required String id,
      required String name,
      required int position,
      Value<int> rowid,
    });
typedef $$SheetRecordsTableUpdateCompanionBuilder =
    SheetRecordsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> position,
      Value<int> rowid,
    });

final class $$SheetRecordsTableReferences
    extends
        BaseReferences<_$ExcelliumDatabase, $SheetRecordsTable, SheetRecord> {
  $$SheetRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ColumnRecordsTable, List<ColumnRecord>>
  _columnRecordsRefsTable(_$ExcelliumDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.columnRecords,
        aliasName: 'sheets__id__columns__sheet_id',
      );

  $$ColumnRecordsTableProcessedTableManager get columnRecordsRefs {
    final manager = $$ColumnRecordsTableTableManager(
      $_db,
      $_db.columnRecords,
    ).filter((f) => f.sheetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_columnRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RowRecordsTable, List<RowRecord>>
  _rowRecordsRefsTable(_$ExcelliumDatabase db) => MultiTypedResultKey.fromTable(
    db.rowRecords,
    aliasName: 'sheets__id__rows__sheet_id',
  );

  $$RowRecordsTableProcessedTableManager get rowRecordsRefs {
    final manager = $$RowRecordsTableTableManager(
      $_db,
      $_db.rowRecords,
    ).filter((f) => f.sheetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rowRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ViewRecordsTable, List<ViewRecord>>
  _viewRecordsRefsTable(_$ExcelliumDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.viewRecords,
        aliasName: 'sheets__id__views__sheet_id',
      );

  $$ViewRecordsTableProcessedTableManager get viewRecordsRefs {
    final manager = $$ViewRecordsTableTableManager(
      $_db,
      $_db.viewRecords,
    ).filter((f) => f.sheetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_viewRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SheetRecordsTableFilterComposer
    extends Composer<_$ExcelliumDatabase, $SheetRecordsTable> {
  $$SheetRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> columnRecordsRefs(
    Expression<bool> Function($$ColumnRecordsTableFilterComposer f) f,
  ) {
    final $$ColumnRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableFilterComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rowRecordsRefs(
    Expression<bool> Function($$RowRecordsTableFilterComposer f) f,
  ) {
    final $$RowRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableFilterComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> viewRecordsRefs(
    Expression<bool> Function($$ViewRecordsTableFilterComposer f) f,
  ) {
    final $$ViewRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.viewRecords,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ViewRecordsTableFilterComposer(
            $db: $db,
            $table: $db.viewRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SheetRecordsTableOrderingComposer
    extends Composer<_$ExcelliumDatabase, $SheetRecordsTable> {
  $$SheetRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SheetRecordsTableAnnotationComposer
    extends Composer<_$ExcelliumDatabase, $SheetRecordsTable> {
  $$SheetRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  Expression<T> columnRecordsRefs<T extends Object>(
    Expression<T> Function($$ColumnRecordsTableAnnotationComposer a) f,
  ) {
    final $$ColumnRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rowRecordsRefs<T extends Object>(
    Expression<T> Function($$RowRecordsTableAnnotationComposer a) f,
  ) {
    final $$RowRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> viewRecordsRefs<T extends Object>(
    Expression<T> Function($$ViewRecordsTableAnnotationComposer a) f,
  ) {
    final $$ViewRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.viewRecords,
      getReferencedColumn: (t) => t.sheetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ViewRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.viewRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SheetRecordsTableTableManager
    extends
        RootTableManager<
          _$ExcelliumDatabase,
          $SheetRecordsTable,
          SheetRecord,
          $$SheetRecordsTableFilterComposer,
          $$SheetRecordsTableOrderingComposer,
          $$SheetRecordsTableAnnotationComposer,
          $$SheetRecordsTableCreateCompanionBuilder,
          $$SheetRecordsTableUpdateCompanionBuilder,
          (SheetRecord, $$SheetRecordsTableReferences),
          SheetRecord,
          PrefetchHooks Function({
            bool columnRecordsRefs,
            bool rowRecordsRefs,
            bool viewRecordsRefs,
          })
        > {
  $$SheetRecordsTableTableManager(
    _$ExcelliumDatabase db,
    $SheetRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SheetRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SheetRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SheetRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SheetRecordsCompanion(
                id: id,
                name: name,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => SheetRecordsCompanion.insert(
                id: id,
                name: name,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SheetRecordsTable, SheetRecord>(table),
                  $$SheetRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                columnRecordsRefs = false,
                rowRecordsRefs = false,
                viewRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (columnRecordsRefs) db.columnRecords,
                    if (rowRecordsRefs) db.rowRecords,
                    if (viewRecordsRefs) db.viewRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (columnRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          SheetRecord,
                          $SheetRecordsTable,
                          ColumnRecord,
                          $ColumnRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SheetRecordsTableReferences
                              ._columnRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SheetRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).columnRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'sheet_id',
                          typedResults: items,
                        ),
                      if (rowRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          SheetRecord,
                          $SheetRecordsTable,
                          RowRecord,
                          $RowRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SheetRecordsTableReferences
                              ._rowRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SheetRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).rowRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'sheet_id',
                          typedResults: items,
                        ),
                      if (viewRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          SheetRecord,
                          $SheetRecordsTable,
                          ViewRecord,
                          $ViewRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SheetRecordsTableReferences
                              ._viewRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SheetRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).viewRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'sheet_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SheetRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExcelliumDatabase,
      $SheetRecordsTable,
      SheetRecord,
      $$SheetRecordsTableFilterComposer,
      $$SheetRecordsTableOrderingComposer,
      $$SheetRecordsTableAnnotationComposer,
      $$SheetRecordsTableCreateCompanionBuilder,
      $$SheetRecordsTableUpdateCompanionBuilder,
      (SheetRecord, $$SheetRecordsTableReferences),
      SheetRecord,
      PrefetchHooks Function({
        bool columnRecordsRefs,
        bool rowRecordsRefs,
        bool viewRecordsRefs,
      })
    >;
typedef $$ColumnRecordsTableCreateCompanionBuilder =
    ColumnRecordsCompanion Function({
      required String id,
      required String sheetId,
      required String name,
      required String type,
      required int position,
      required double width,
      Value<String?> reference,
      Value<String?> style,
      Value<String?> options,
      Value<String?> formula,
      Value<String?> groupCalc,
      Value<String?> calcCells,
      Value<int> rowid,
    });
typedef $$ColumnRecordsTableUpdateCompanionBuilder =
    ColumnRecordsCompanion Function({
      Value<String> id,
      Value<String> sheetId,
      Value<String> name,
      Value<String> type,
      Value<int> position,
      Value<double> width,
      Value<String?> reference,
      Value<String?> style,
      Value<String?> options,
      Value<String?> formula,
      Value<String?> groupCalc,
      Value<String?> calcCells,
      Value<int> rowid,
    });

final class $$ColumnRecordsTableReferences
    extends
        BaseReferences<_$ExcelliumDatabase, $ColumnRecordsTable, ColumnRecord> {
  $$ColumnRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SheetRecordsTable _sheetIdTable(_$ExcelliumDatabase db) =>
      db.sheetRecords.createAlias('columns__sheet_id__sheets__id');

  $$SheetRecordsTableProcessedTableManager get sheetId {
    final $_column = $_itemColumn<String>('sheet_id')!;

    final manager = $$SheetRecordsTableTableManager(
      $_db,
      $_db.sheetRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sheetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CellRecordsTable, List<CellRecord>>
  _cellRecordsRefsTable(_$ExcelliumDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cellRecords,
        aliasName: 'columns__id__cells__column_id',
      );

  $$CellRecordsTableProcessedTableManager get cellRecordsRefs {
    final manager = $$CellRecordsTableTableManager(
      $_db,
      $_db.cellRecords,
    ).filter((f) => f.columnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cellRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CellStyleRecordsTable, List<CellStyleRecord>>
  _cellStyleRecordsRefsTable(_$ExcelliumDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cellStyleRecords,
        aliasName: 'columns__id__cell_styles__column_id',
      );

  $$CellStyleRecordsTableProcessedTableManager get cellStyleRecordsRefs {
    final manager = $$CellStyleRecordsTableTableManager(
      $_db,
      $_db.cellStyleRecords,
    ).filter((f) => f.columnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cellStyleRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ColumnRecordsTableFilterComposer
    extends Composer<_$ExcelliumDatabase, $ColumnRecordsTable> {
  $$ColumnRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formula => $composableBuilder(
    column: $table.formula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupCalc => $composableBuilder(
    column: $table.groupCalc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calcCells => $composableBuilder(
    column: $table.calcCells,
    builder: (column) => ColumnFilters(column),
  );

  $$SheetRecordsTableFilterComposer get sheetId {
    final $$SheetRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableFilterComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cellRecordsRefs(
    Expression<bool> Function($$CellRecordsTableFilterComposer f) f,
  ) {
    final $$CellRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellRecords,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellRecordsTableFilterComposer(
            $db: $db,
            $table: $db.cellRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cellStyleRecordsRefs(
    Expression<bool> Function($$CellStyleRecordsTableFilterComposer f) f,
  ) {
    final $$CellStyleRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellStyleRecords,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellStyleRecordsTableFilterComposer(
            $db: $db,
            $table: $db.cellStyleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ColumnRecordsTableOrderingComposer
    extends Composer<_$ExcelliumDatabase, $ColumnRecordsTable> {
  $$ColumnRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formula => $composableBuilder(
    column: $table.formula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupCalc => $composableBuilder(
    column: $table.groupCalc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calcCells => $composableBuilder(
    column: $table.calcCells,
    builder: (column) => ColumnOrderings(column),
  );

  $$SheetRecordsTableOrderingComposer get sheetId {
    final $$SheetRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ColumnRecordsTableAnnotationComposer
    extends Composer<_$ExcelliumDatabase, $ColumnRecordsTable> {
  $$ColumnRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get formula =>
      $composableBuilder(column: $table.formula, builder: (column) => column);

  GeneratedColumn<String> get groupCalc =>
      $composableBuilder(column: $table.groupCalc, builder: (column) => column);

  GeneratedColumn<String> get calcCells =>
      $composableBuilder(column: $table.calcCells, builder: (column) => column);

  $$SheetRecordsTableAnnotationComposer get sheetId {
    final $$SheetRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cellRecordsRefs<T extends Object>(
    Expression<T> Function($$CellRecordsTableAnnotationComposer a) f,
  ) {
    final $$CellRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellRecords,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.cellRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cellStyleRecordsRefs<T extends Object>(
    Expression<T> Function($$CellStyleRecordsTableAnnotationComposer a) f,
  ) {
    final $$CellStyleRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellStyleRecords,
      getReferencedColumn: (t) => t.columnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellStyleRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.cellStyleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ColumnRecordsTableTableManager
    extends
        RootTableManager<
          _$ExcelliumDatabase,
          $ColumnRecordsTable,
          ColumnRecord,
          $$ColumnRecordsTableFilterComposer,
          $$ColumnRecordsTableOrderingComposer,
          $$ColumnRecordsTableAnnotationComposer,
          $$ColumnRecordsTableCreateCompanionBuilder,
          $$ColumnRecordsTableUpdateCompanionBuilder,
          (ColumnRecord, $$ColumnRecordsTableReferences),
          ColumnRecord,
          PrefetchHooks Function({
            bool sheetId,
            bool cellRecordsRefs,
            bool cellStyleRecordsRefs,
          })
        > {
  $$ColumnRecordsTableTableManager(
    _$ExcelliumDatabase db,
    $ColumnRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ColumnRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ColumnRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ColumnRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sheetId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> style = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<String?> formula = const Value.absent(),
                Value<String?> groupCalc = const Value.absent(),
                Value<String?> calcCells = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColumnRecordsCompanion(
                id: id,
                sheetId: sheetId,
                name: name,
                type: type,
                position: position,
                width: width,
                reference: reference,
                style: style,
                options: options,
                formula: formula,
                groupCalc: groupCalc,
                calcCells: calcCells,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sheetId,
                required String name,
                required String type,
                required int position,
                required double width,
                Value<String?> reference = const Value.absent(),
                Value<String?> style = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<String?> formula = const Value.absent(),
                Value<String?> groupCalc = const Value.absent(),
                Value<String?> calcCells = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColumnRecordsCompanion.insert(
                id: id,
                sheetId: sheetId,
                name: name,
                type: type,
                position: position,
                width: width,
                reference: reference,
                style: style,
                options: options,
                formula: formula,
                groupCalc: groupCalc,
                calcCells: calcCells,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ColumnRecordsTable, ColumnRecord>(table),
                  $$ColumnRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sheetId = false,
                cellRecordsRefs = false,
                cellStyleRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cellRecordsRefs) db.cellRecords,
                    if (cellStyleRecordsRefs) db.cellStyleRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sheetId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sheetId,
                            referencedTable: $$ColumnRecordsTableReferences
                                ._sheetIdTable(db),
                            referencedColumn: $$ColumnRecordsTableReferences
                                ._sheetIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cellRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          ColumnRecord,
                          $ColumnRecordsTable,
                          CellRecord,
                          $CellRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ColumnRecordsTableReferences
                              ._cellRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ColumnRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).cellRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'column_id',
                          typedResults: items,
                        ),
                      if (cellStyleRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          ColumnRecord,
                          $ColumnRecordsTable,
                          CellStyleRecord,
                          $CellStyleRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ColumnRecordsTableReferences
                              ._cellStyleRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ColumnRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).cellStyleRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'column_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ColumnRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExcelliumDatabase,
      $ColumnRecordsTable,
      ColumnRecord,
      $$ColumnRecordsTableFilterComposer,
      $$ColumnRecordsTableOrderingComposer,
      $$ColumnRecordsTableAnnotationComposer,
      $$ColumnRecordsTableCreateCompanionBuilder,
      $$ColumnRecordsTableUpdateCompanionBuilder,
      (ColumnRecord, $$ColumnRecordsTableReferences),
      ColumnRecord,
      PrefetchHooks Function({
        bool sheetId,
        bool cellRecordsRefs,
        bool cellStyleRecordsRefs,
      })
    >;
typedef $$RowRecordsTableCreateCompanionBuilder = RowRecordsCompanion Function({
  required String id,
  required String sheetId,
  required int position,
  Value<double?> height,
  Value<int> rowid,
});
typedef $$RowRecordsTableUpdateCompanionBuilder = RowRecordsCompanion Function({
  Value<String> id,
  Value<String> sheetId,
  Value<int> position,
  Value<double?> height,
  Value<int> rowid,
});

final class $$RowRecordsTableReferences
    extends BaseReferences<_$ExcelliumDatabase, $RowRecordsTable, RowRecord> {
  $$RowRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SheetRecordsTable _sheetIdTable(_$ExcelliumDatabase db) =>
      db.sheetRecords.createAlias('rows__sheet_id__sheets__id');

  $$SheetRecordsTableProcessedTableManager get sheetId {
    final $_column = $_itemColumn<String>('sheet_id')!;

    final manager = $$SheetRecordsTableTableManager(
      $_db,
      $_db.sheetRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sheetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CellRecordsTable, List<CellRecord>>
  _cellRecordsRefsTable(_$ExcelliumDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cellRecords,
        aliasName: 'rows__id__cells__row_id',
      );

  $$CellRecordsTableProcessedTableManager get cellRecordsRefs {
    final manager = $$CellRecordsTableTableManager(
      $_db,
      $_db.cellRecords,
    ).filter((f) => f.rowId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cellRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CellStyleRecordsTable, List<CellStyleRecord>>
  _cellStyleRecordsRefsTable(_$ExcelliumDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cellStyleRecords,
        aliasName: 'rows__id__cell_styles__row_id',
      );

  $$CellStyleRecordsTableProcessedTableManager get cellStyleRecordsRefs {
    final manager = $$CellStyleRecordsTableTableManager(
      $_db,
      $_db.cellStyleRecords,
    ).filter((f) => f.rowId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cellStyleRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RowRecordsTableFilterComposer
    extends Composer<_$ExcelliumDatabase, $RowRecordsTable> {
  $$RowRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  $$SheetRecordsTableFilterComposer get sheetId {
    final $$SheetRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableFilterComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cellRecordsRefs(
    Expression<bool> Function($$CellRecordsTableFilterComposer f) f,
  ) {
    final $$CellRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellRecords,
      getReferencedColumn: (t) => t.rowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellRecordsTableFilterComposer(
            $db: $db,
            $table: $db.cellRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cellStyleRecordsRefs(
    Expression<bool> Function($$CellStyleRecordsTableFilterComposer f) f,
  ) {
    final $$CellStyleRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellStyleRecords,
      getReferencedColumn: (t) => t.rowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellStyleRecordsTableFilterComposer(
            $db: $db,
            $table: $db.cellStyleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RowRecordsTableOrderingComposer
    extends Composer<_$ExcelliumDatabase, $RowRecordsTable> {
  $$RowRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  $$SheetRecordsTableOrderingComposer get sheetId {
    final $$SheetRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RowRecordsTableAnnotationComposer
    extends Composer<_$ExcelliumDatabase, $RowRecordsTable> {
  $$RowRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  $$SheetRecordsTableAnnotationComposer get sheetId {
    final $$SheetRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cellRecordsRefs<T extends Object>(
    Expression<T> Function($$CellRecordsTableAnnotationComposer a) f,
  ) {
    final $$CellRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellRecords,
      getReferencedColumn: (t) => t.rowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.cellRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cellStyleRecordsRefs<T extends Object>(
    Expression<T> Function($$CellStyleRecordsTableAnnotationComposer a) f,
  ) {
    final $$CellStyleRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cellStyleRecords,
      getReferencedColumn: (t) => t.rowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CellStyleRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.cellStyleRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RowRecordsTableTableManager
    extends
        RootTableManager<
          _$ExcelliumDatabase,
          $RowRecordsTable,
          RowRecord,
          $$RowRecordsTableFilterComposer,
          $$RowRecordsTableOrderingComposer,
          $$RowRecordsTableAnnotationComposer,
          $$RowRecordsTableCreateCompanionBuilder,
          $$RowRecordsTableUpdateCompanionBuilder,
          (RowRecord, $$RowRecordsTableReferences),
          RowRecord,
          PrefetchHooks Function({
            bool sheetId,
            bool cellRecordsRefs,
            bool cellStyleRecordsRefs,
          })
        > {
  $$RowRecordsTableTableManager(_$ExcelliumDatabase db, $RowRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RowRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RowRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RowRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sheetId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<double?> height = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RowRecordsCompanion(
                id: id,
                sheetId: sheetId,
                position: position,
                height: height,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sheetId,
                required int position,
                Value<double?> height = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RowRecordsCompanion.insert(
                id: id,
                sheetId: sheetId,
                position: position,
                height: height,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RowRecordsTable, RowRecord>(table),
                  $$RowRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sheetId = false,
                cellRecordsRefs = false,
                cellStyleRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cellRecordsRefs) db.cellRecords,
                    if (cellStyleRecordsRefs) db.cellStyleRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sheetId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sheetId,
                            referencedTable: $$RowRecordsTableReferences
                                ._sheetIdTable(db),
                            referencedColumn: $$RowRecordsTableReferences
                                ._sheetIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cellRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          RowRecord,
                          $RowRecordsTable,
                          CellRecord,
                          $CellRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RowRecordsTableReferences
                              ._cellRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RowRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).cellRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'row_id',
                          typedResults: items,
                        ),
                      if (cellStyleRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          RowRecord,
                          $RowRecordsTable,
                          CellStyleRecord,
                          $CellStyleRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RowRecordsTableReferences
                              ._cellStyleRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RowRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).cellStyleRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'row_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RowRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExcelliumDatabase,
      $RowRecordsTable,
      RowRecord,
      $$RowRecordsTableFilterComposer,
      $$RowRecordsTableOrderingComposer,
      $$RowRecordsTableAnnotationComposer,
      $$RowRecordsTableCreateCompanionBuilder,
      $$RowRecordsTableUpdateCompanionBuilder,
      (RowRecord, $$RowRecordsTableReferences),
      RowRecord,
      PrefetchHooks Function({
        bool sheetId,
        bool cellRecordsRefs,
        bool cellStyleRecordsRefs,
      })
    >;
typedef $$CellRecordsTableCreateCompanionBuilder =
    CellRecordsCompanion Function({
      required String rowId,
      required String columnId,
      required String value,
      Value<int> rowid,
    });
typedef $$CellRecordsTableUpdateCompanionBuilder =
    CellRecordsCompanion Function({
      Value<String> rowId,
      Value<String> columnId,
      Value<String> value,
      Value<int> rowid,
    });

final class $$CellRecordsTableReferences
    extends BaseReferences<_$ExcelliumDatabase, $CellRecordsTable, CellRecord> {
  $$CellRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RowRecordsTable _rowIdTable(_$ExcelliumDatabase db) =>
      db.rowRecords.createAlias('cells__row_id__rows__id');

  $$RowRecordsTableProcessedTableManager get rowId {
    final $_column = $_itemColumn<String>('row_id')!;

    final manager = $$RowRecordsTableTableManager(
      $_db,
      $_db.rowRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ColumnRecordsTable _columnIdTable(_$ExcelliumDatabase db) =>
      db.columnRecords.createAlias('cells__column_id__columns__id');

  $$ColumnRecordsTableProcessedTableManager get columnId {
    final $_column = $_itemColumn<String>('column_id')!;

    final manager = $$ColumnRecordsTableTableManager(
      $_db,
      $_db.columnRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_columnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CellRecordsTableFilterComposer
    extends Composer<_$ExcelliumDatabase, $CellRecordsTable> {
  $$CellRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$RowRecordsTableFilterComposer get rowId {
    final $$RowRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rowId,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableFilterComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ColumnRecordsTableFilterComposer get columnId {
    final $$ColumnRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableFilterComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CellRecordsTableOrderingComposer
    extends Composer<_$ExcelliumDatabase, $CellRecordsTable> {
  $$CellRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$RowRecordsTableOrderingComposer get rowId {
    final $$RowRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rowId,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ColumnRecordsTableOrderingComposer get columnId {
    final $$ColumnRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CellRecordsTableAnnotationComposer
    extends Composer<_$ExcelliumDatabase, $CellRecordsTable> {
  $$CellRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$RowRecordsTableAnnotationComposer get rowId {
    final $$RowRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rowId,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ColumnRecordsTableAnnotationComposer get columnId {
    final $$ColumnRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CellRecordsTableTableManager
    extends
        RootTableManager<
          _$ExcelliumDatabase,
          $CellRecordsTable,
          CellRecord,
          $$CellRecordsTableFilterComposer,
          $$CellRecordsTableOrderingComposer,
          $$CellRecordsTableAnnotationComposer,
          $$CellRecordsTableCreateCompanionBuilder,
          $$CellRecordsTableUpdateCompanionBuilder,
          (CellRecord, $$CellRecordsTableReferences),
          CellRecord,
          PrefetchHooks Function({bool rowId, bool columnId})
        > {
  $$CellRecordsTableTableManager(
    _$ExcelliumDatabase db,
    $CellRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CellRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CellRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CellRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rowId = const Value.absent(),
                Value<String> columnId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CellRecordsCompanion(
                rowId: rowId,
                columnId: columnId,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rowId,
                required String columnId,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => CellRecordsCompanion.insert(
                rowId: rowId,
                columnId: columnId,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CellRecordsTable, CellRecord>(table),
                  $$CellRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({rowId = false, columnId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (rowId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.rowId,
                        referencedTable: $$CellRecordsTableReferences
                            ._rowIdTable(db),
                        referencedColumn: $$CellRecordsTableReferences
                            ._rowIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (columnId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.columnId,
                        referencedTable: $$CellRecordsTableReferences
                            ._columnIdTable(db),
                        referencedColumn: $$CellRecordsTableReferences
                            ._columnIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CellRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExcelliumDatabase,
      $CellRecordsTable,
      CellRecord,
      $$CellRecordsTableFilterComposer,
      $$CellRecordsTableOrderingComposer,
      $$CellRecordsTableAnnotationComposer,
      $$CellRecordsTableCreateCompanionBuilder,
      $$CellRecordsTableUpdateCompanionBuilder,
      (CellRecord, $$CellRecordsTableReferences),
      CellRecord,
      PrefetchHooks Function({bool rowId, bool columnId})
    >;
typedef $$CellStyleRecordsTableCreateCompanionBuilder =
    CellStyleRecordsCompanion Function({
      required String rowId,
      required String columnId,
      required String style,
      Value<int> rowid,
    });
typedef $$CellStyleRecordsTableUpdateCompanionBuilder =
    CellStyleRecordsCompanion Function({
      Value<String> rowId,
      Value<String> columnId,
      Value<String> style,
      Value<int> rowid,
    });

final class $$CellStyleRecordsTableReferences
    extends
        BaseReferences<
          _$ExcelliumDatabase,
          $CellStyleRecordsTable,
          CellStyleRecord
        > {
  $$CellStyleRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RowRecordsTable _rowIdTable(_$ExcelliumDatabase db) =>
      db.rowRecords.createAlias('cell_styles__row_id__rows__id');

  $$RowRecordsTableProcessedTableManager get rowId {
    final $_column = $_itemColumn<String>('row_id')!;

    final manager = $$RowRecordsTableTableManager(
      $_db,
      $_db.rowRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ColumnRecordsTable _columnIdTable(_$ExcelliumDatabase db) =>
      db.columnRecords.createAlias('cell_styles__column_id__columns__id');

  $$ColumnRecordsTableProcessedTableManager get columnId {
    final $_column = $_itemColumn<String>('column_id')!;

    final manager = $$ColumnRecordsTableTableManager(
      $_db,
      $_db.columnRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_columnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CellStyleRecordsTableFilterComposer
    extends Composer<_$ExcelliumDatabase, $CellStyleRecordsTable> {
  $$CellStyleRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  $$RowRecordsTableFilterComposer get rowId {
    final $$RowRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rowId,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableFilterComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ColumnRecordsTableFilterComposer get columnId {
    final $$ColumnRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableFilterComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CellStyleRecordsTableOrderingComposer
    extends Composer<_$ExcelliumDatabase, $CellStyleRecordsTable> {
  $$CellStyleRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  $$RowRecordsTableOrderingComposer get rowId {
    final $$RowRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rowId,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ColumnRecordsTableOrderingComposer get columnId {
    final $$ColumnRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CellStyleRecordsTableAnnotationComposer
    extends Composer<_$ExcelliumDatabase, $CellStyleRecordsTable> {
  $$CellStyleRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  $$RowRecordsTableAnnotationComposer get rowId {
    final $$RowRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rowId,
      referencedTable: $db.rowRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RowRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.rowRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ColumnRecordsTableAnnotationComposer get columnId {
    final $$ColumnRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.columnId,
      referencedTable: $db.columnRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ColumnRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.columnRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CellStyleRecordsTableTableManager
    extends
        RootTableManager<
          _$ExcelliumDatabase,
          $CellStyleRecordsTable,
          CellStyleRecord,
          $$CellStyleRecordsTableFilterComposer,
          $$CellStyleRecordsTableOrderingComposer,
          $$CellStyleRecordsTableAnnotationComposer,
          $$CellStyleRecordsTableCreateCompanionBuilder,
          $$CellStyleRecordsTableUpdateCompanionBuilder,
          (CellStyleRecord, $$CellStyleRecordsTableReferences),
          CellStyleRecord,
          PrefetchHooks Function({bool rowId, bool columnId})
        > {
  $$CellStyleRecordsTableTableManager(
    _$ExcelliumDatabase db,
    $CellStyleRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CellStyleRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CellStyleRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CellStyleRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rowId = const Value.absent(),
                Value<String> columnId = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CellStyleRecordsCompanion(
                rowId: rowId,
                columnId: columnId,
                style: style,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rowId,
                required String columnId,
                required String style,
                Value<int> rowid = const Value.absent(),
              }) => CellStyleRecordsCompanion.insert(
                rowId: rowId,
                columnId: columnId,
                style: style,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CellStyleRecordsTable, CellStyleRecord>(table),
                  $$CellStyleRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({rowId = false, columnId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (rowId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.rowId,
                        referencedTable: $$CellStyleRecordsTableReferences
                            ._rowIdTable(db),
                        referencedColumn: $$CellStyleRecordsTableReferences
                            ._rowIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (columnId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.columnId,
                        referencedTable: $$CellStyleRecordsTableReferences
                            ._columnIdTable(db),
                        referencedColumn: $$CellStyleRecordsTableReferences
                            ._columnIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CellStyleRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExcelliumDatabase,
      $CellStyleRecordsTable,
      CellStyleRecord,
      $$CellStyleRecordsTableFilterComposer,
      $$CellStyleRecordsTableOrderingComposer,
      $$CellStyleRecordsTableAnnotationComposer,
      $$CellStyleRecordsTableCreateCompanionBuilder,
      $$CellStyleRecordsTableUpdateCompanionBuilder,
      (CellStyleRecord, $$CellStyleRecordsTableReferences),
      CellStyleRecord,
      PrefetchHooks Function({bool rowId, bool columnId})
    >;
typedef $$ViewRecordsTableCreateCompanionBuilder =
    ViewRecordsCompanion Function({
      required String id,
      required String sheetId,
      required String name,
      required int position,
      required String spec,
      Value<int> rowid,
    });
typedef $$ViewRecordsTableUpdateCompanionBuilder =
    ViewRecordsCompanion Function({
      Value<String> id,
      Value<String> sheetId,
      Value<String> name,
      Value<int> position,
      Value<String> spec,
      Value<int> rowid,
    });

final class $$ViewRecordsTableReferences
    extends BaseReferences<_$ExcelliumDatabase, $ViewRecordsTable, ViewRecord> {
  $$ViewRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SheetRecordsTable _sheetIdTable(_$ExcelliumDatabase db) =>
      db.sheetRecords.createAlias('views__sheet_id__sheets__id');

  $$SheetRecordsTableProcessedTableManager get sheetId {
    final $_column = $_itemColumn<String>('sheet_id')!;

    final manager = $$SheetRecordsTableTableManager(
      $_db,
      $_db.sheetRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sheetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ViewRecordsTableFilterComposer
    extends Composer<_$ExcelliumDatabase, $ViewRecordsTable> {
  $$ViewRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spec => $composableBuilder(
    column: $table.spec,
    builder: (column) => ColumnFilters(column),
  );

  $$SheetRecordsTableFilterComposer get sheetId {
    final $$SheetRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableFilterComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ViewRecordsTableOrderingComposer
    extends Composer<_$ExcelliumDatabase, $ViewRecordsTable> {
  $$ViewRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spec => $composableBuilder(
    column: $table.spec,
    builder: (column) => ColumnOrderings(column),
  );

  $$SheetRecordsTableOrderingComposer get sheetId {
    final $$SheetRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ViewRecordsTableAnnotationComposer
    extends Composer<_$ExcelliumDatabase, $ViewRecordsTable> {
  $$ViewRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get spec =>
      $composableBuilder(column: $table.spec, builder: (column) => column);

  $$SheetRecordsTableAnnotationComposer get sheetId {
    final $$SheetRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetId,
      referencedTable: $db.sheetRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.sheetRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ViewRecordsTableTableManager
    extends
        RootTableManager<
          _$ExcelliumDatabase,
          $ViewRecordsTable,
          ViewRecord,
          $$ViewRecordsTableFilterComposer,
          $$ViewRecordsTableOrderingComposer,
          $$ViewRecordsTableAnnotationComposer,
          $$ViewRecordsTableCreateCompanionBuilder,
          $$ViewRecordsTableUpdateCompanionBuilder,
          (ViewRecord, $$ViewRecordsTableReferences),
          ViewRecord,
          PrefetchHooks Function({bool sheetId})
        > {
  $$ViewRecordsTableTableManager(
    _$ExcelliumDatabase db,
    $ViewRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ViewRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ViewRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ViewRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sheetId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> spec = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ViewRecordsCompanion(
                id: id,
                sheetId: sheetId,
                name: name,
                position: position,
                spec: spec,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sheetId,
                required String name,
                required int position,
                required String spec,
                Value<int> rowid = const Value.absent(),
              }) => ViewRecordsCompanion.insert(
                id: id,
                sheetId: sheetId,
                name: name,
                position: position,
                spec: spec,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ViewRecordsTable, ViewRecord>(table),
                  $$ViewRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sheetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sheetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sheetId,
                        referencedTable: $$ViewRecordsTableReferences
                            ._sheetIdTable(db),
                        referencedColumn: $$ViewRecordsTableReferences
                            ._sheetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ViewRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$ExcelliumDatabase,
      $ViewRecordsTable,
      ViewRecord,
      $$ViewRecordsTableFilterComposer,
      $$ViewRecordsTableOrderingComposer,
      $$ViewRecordsTableAnnotationComposer,
      $$ViewRecordsTableCreateCompanionBuilder,
      $$ViewRecordsTableUpdateCompanionBuilder,
      (ViewRecord, $$ViewRecordsTableReferences),
      ViewRecord,
      PrefetchHooks Function({bool sheetId})
    >;

class $ExcelliumDatabaseManager {
  final _$ExcelliumDatabase _db;
  $ExcelliumDatabaseManager(this._db);
  $$SheetRecordsTableTableManager get sheetRecords =>
      $$SheetRecordsTableTableManager(_db, _db.sheetRecords);
  $$ColumnRecordsTableTableManager get columnRecords =>
      $$ColumnRecordsTableTableManager(_db, _db.columnRecords);
  $$RowRecordsTableTableManager get rowRecords =>
      $$RowRecordsTableTableManager(_db, _db.rowRecords);
  $$CellRecordsTableTableManager get cellRecords =>
      $$CellRecordsTableTableManager(_db, _db.cellRecords);
  $$CellStyleRecordsTableTableManager get cellStyleRecords =>
      $$CellStyleRecordsTableTableManager(_db, _db.cellStyleRecords);
  $$ViewRecordsTableTableManager get viewRecords =>
      $$ViewRecordsTableTableManager(_db, _db.viewRecords);
}
