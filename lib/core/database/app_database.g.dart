// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DatasetsTable extends Datasets with TableInfo<$DatasetsTable, Dataset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceFileNameMeta =
      const VerificationMeta('sourceFileName');
  @override
  late final GeneratedColumn<String> sourceFileName = GeneratedColumn<String>(
      'source_file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceFileHashMeta =
      const VerificationMeta('sourceFileHash');
  @override
  late final GeneratedColumn<String> sourceFileHash = GeneratedColumn<String>(
      'source_file_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<int> lastOpenedAt = GeneratedColumn<int>(
      'last_opened_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uiStateJsonMeta =
      const VerificationMeta('uiStateJson');
  @override
  late final GeneratedColumn<String> uiStateJson = GeneratedColumn<String>(
      'ui_state_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        sourceFileName,
        sourceFileHash,
        createdAt,
        lastOpenedAt,
        uiStateJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'datasets';
  @override
  VerificationContext validateIntegrity(Insertable<Dataset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_file_name')) {
      context.handle(
          _sourceFileNameMeta,
          sourceFileName.isAcceptableOrUnknown(
              data['source_file_name']!, _sourceFileNameMeta));
    } else if (isInserting) {
      context.missing(_sourceFileNameMeta);
    }
    if (data.containsKey('source_file_hash')) {
      context.handle(
          _sourceFileHashMeta,
          sourceFileHash.isAcceptableOrUnknown(
              data['source_file_hash']!, _sourceFileHashMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    }
    if (data.containsKey('ui_state_json')) {
      context.handle(
          _uiStateJsonMeta,
          uiStateJson.isAcceptableOrUnknown(
              data['ui_state_json']!, _uiStateJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dataset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dataset(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sourceFileName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_name'])!,
      sourceFileHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_hash']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastOpenedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_opened_at']),
      uiStateJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ui_state_json']),
    );
  }

  @override
  $DatasetsTable createAlias(String alias) {
    return $DatasetsTable(attachedDatabase, alias);
  }
}

class Dataset extends DataClass implements Insertable<Dataset> {
  /// Primary key (auto increment)
  final int id;

  /// Human readable name (e.g. "Import 2026-03-04 - Suppliers")
  final String name;

  /// Original file name imported by the user
  final String sourceFileName;

  /// Optional file hash (useful to detect re-import of same file)
  final String? sourceFileHash;

  /// Unix timestamp (milliseconds) when the dataset was created
  final int createdAt;

  /// Unix timestamp (milliseconds) when last opened
  final int? lastOpenedAt;

  /// Serialized UI state (filters, sorting, visible columns, etc.)
  final String? uiStateJson;
  const Dataset(
      {required this.id,
      required this.name,
      required this.sourceFileName,
      this.sourceFileHash,
      required this.createdAt,
      this.lastOpenedAt,
      this.uiStateJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source_file_name'] = Variable<String>(sourceFileName);
    if (!nullToAbsent || sourceFileHash != null) {
      map['source_file_hash'] = Variable<String>(sourceFileHash);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt);
    }
    if (!nullToAbsent || uiStateJson != null) {
      map['ui_state_json'] = Variable<String>(uiStateJson);
    }
    return map;
  }

  DatasetsCompanion toCompanion(bool nullToAbsent) {
    return DatasetsCompanion(
      id: Value(id),
      name: Value(name),
      sourceFileName: Value(sourceFileName),
      sourceFileHash: sourceFileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFileHash),
      createdAt: Value(createdAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      uiStateJson: uiStateJson == null && nullToAbsent
          ? const Value.absent()
          : Value(uiStateJson),
    );
  }

  factory Dataset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dataset(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceFileName: serializer.fromJson<String>(json['sourceFileName']),
      sourceFileHash: serializer.fromJson<String?>(json['sourceFileHash']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastOpenedAt: serializer.fromJson<int?>(json['lastOpenedAt']),
      uiStateJson: serializer.fromJson<String?>(json['uiStateJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sourceFileName': serializer.toJson<String>(sourceFileName),
      'sourceFileHash': serializer.toJson<String?>(sourceFileHash),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastOpenedAt': serializer.toJson<int?>(lastOpenedAt),
      'uiStateJson': serializer.toJson<String?>(uiStateJson),
    };
  }

  Dataset copyWith(
          {int? id,
          String? name,
          String? sourceFileName,
          Value<String?> sourceFileHash = const Value.absent(),
          int? createdAt,
          Value<int?> lastOpenedAt = const Value.absent(),
          Value<String?> uiStateJson = const Value.absent()}) =>
      Dataset(
        id: id ?? this.id,
        name: name ?? this.name,
        sourceFileName: sourceFileName ?? this.sourceFileName,
        sourceFileHash:
            sourceFileHash.present ? sourceFileHash.value : this.sourceFileHash,
        createdAt: createdAt ?? this.createdAt,
        lastOpenedAt:
            lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
        uiStateJson: uiStateJson.present ? uiStateJson.value : this.uiStateJson,
      );
  Dataset copyWithCompanion(DatasetsCompanion data) {
    return Dataset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceFileName: data.sourceFileName.present
          ? data.sourceFileName.value
          : this.sourceFileName,
      sourceFileHash: data.sourceFileHash.present
          ? data.sourceFileHash.value
          : this.sourceFileHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      uiStateJson:
          data.uiStateJson.present ? data.uiStateJson.value : this.uiStateJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dataset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('uiStateJson: $uiStateJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sourceFileName, sourceFileHash,
      createdAt, lastOpenedAt, uiStateJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dataset &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceFileName == this.sourceFileName &&
          other.sourceFileHash == this.sourceFileHash &&
          other.createdAt == this.createdAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.uiStateJson == this.uiStateJson);
}

class DatasetsCompanion extends UpdateCompanion<Dataset> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> sourceFileName;
  final Value<String?> sourceFileHash;
  final Value<int> createdAt;
  final Value<int?> lastOpenedAt;
  final Value<String?> uiStateJson;
  const DatasetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceFileName = const Value.absent(),
    this.sourceFileHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.uiStateJson = const Value.absent(),
  });
  DatasetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String sourceFileName,
    this.sourceFileHash = const Value.absent(),
    required int createdAt,
    this.lastOpenedAt = const Value.absent(),
    this.uiStateJson = const Value.absent(),
  })  : name = Value(name),
        sourceFileName = Value(sourceFileName),
        createdAt = Value(createdAt);
  static Insertable<Dataset> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sourceFileName,
    Expression<String>? sourceFileHash,
    Expression<int>? createdAt,
    Expression<int>? lastOpenedAt,
    Expression<String>? uiStateJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceFileName != null) 'source_file_name': sourceFileName,
      if (sourceFileHash != null) 'source_file_hash': sourceFileHash,
      if (createdAt != null) 'created_at': createdAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (uiStateJson != null) 'ui_state_json': uiStateJson,
    });
  }

  DatasetsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? sourceFileName,
      Value<String?>? sourceFileHash,
      Value<int>? createdAt,
      Value<int?>? lastOpenedAt,
      Value<String?>? uiStateJson}) {
    return DatasetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      sourceFileHash: sourceFileHash ?? this.sourceFileHash,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      uiStateJson: uiStateJson ?? this.uiStateJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceFileName.present) {
      map['source_file_name'] = Variable<String>(sourceFileName.value);
    }
    if (sourceFileHash.present) {
      map['source_file_hash'] = Variable<String>(sourceFileHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt.value);
    }
    if (uiStateJson.present) {
      map['ui_state_json'] = Variable<String>(uiStateJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('uiStateJson: $uiStateJson')
          ..write(')'))
        .toString();
  }
}

class $DatasetTablesTable extends DatasetTables
    with TableInfo<$DatasetTablesTable, DatasetTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datasetIdMeta =
      const VerificationMeta('datasetId');
  @override
  late final GeneratedColumn<int> datasetId = GeneratedColumn<int>(
      'dataset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES datasets (id)'));
  static const VerificationMeta _sheetNameOriginalMeta =
      const VerificationMeta('sheetNameOriginal');
  @override
  late final GeneratedColumn<String> sheetNameOriginal =
      GeneratedColumn<String>('sheet_name_original', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sqlTableNameMeta =
      const VerificationMeta('sqlTableName');
  @override
  late final GeneratedColumn<String> sqlTableName = GeneratedColumn<String>(
      'sql_table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rowCountMeta =
      const VerificationMeta('rowCount');
  @override
  late final GeneratedColumn<int> rowCount = GeneratedColumn<int>(
      'row_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colCountMeta =
      const VerificationMeta('colCount');
  @override
  late final GeneratedColumn<int> colCount = GeneratedColumn<int>(
      'col_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, datasetId, sheetNameOriginal, sqlTableName, rowCount, colCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_tables';
  @override
  VerificationContext validateIntegrity(Insertable<DatasetTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_id')) {
      context.handle(_datasetIdMeta,
          datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta));
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('sheet_name_original')) {
      context.handle(
          _sheetNameOriginalMeta,
          sheetNameOriginal.isAcceptableOrUnknown(
              data['sheet_name_original']!, _sheetNameOriginalMeta));
    } else if (isInserting) {
      context.missing(_sheetNameOriginalMeta);
    }
    if (data.containsKey('sql_table_name')) {
      context.handle(
          _sqlTableNameMeta,
          sqlTableName.isAcceptableOrUnknown(
              data['sql_table_name']!, _sqlTableNameMeta));
    } else if (isInserting) {
      context.missing(_sqlTableNameMeta);
    }
    if (data.containsKey('row_count')) {
      context.handle(_rowCountMeta,
          rowCount.isAcceptableOrUnknown(data['row_count']!, _rowCountMeta));
    } else if (isInserting) {
      context.missing(_rowCountMeta);
    }
    if (data.containsKey('col_count')) {
      context.handle(_colCountMeta,
          colCount.isAcceptableOrUnknown(data['col_count']!, _colCountMeta));
    } else if (isInserting) {
      context.missing(_colCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datasetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dataset_id'])!,
      sheetNameOriginal: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sheet_name_original'])!,
      sqlTableName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sql_table_name'])!,
      rowCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}row_count'])!,
      colCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}col_count'])!,
    );
  }

  @override
  $DatasetTablesTable createAlias(String alias) {
    return $DatasetTablesTable(attachedDatabase, alias);
  }
}

class DatasetTable extends DataClass implements Insertable<DatasetTable> {
  final int id;

  /// Foreign key to Datasets.id
  final int datasetId;

  /// Original sheet name inside Excel file
  final String sheetNameOriginal;

  /// Actual SQL table name (e.g. ds_12_sheet_1)
  final String sqlTableName;

  /// Number of rows inserted into this table
  final int rowCount;

  /// Number of columns created (denormalized for quick access)
  final int colCount;
  const DatasetTable(
      {required this.id,
      required this.datasetId,
      required this.sheetNameOriginal,
      required this.sqlTableName,
      required this.rowCount,
      required this.colCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_id'] = Variable<int>(datasetId);
    map['sheet_name_original'] = Variable<String>(sheetNameOriginal);
    map['sql_table_name'] = Variable<String>(sqlTableName);
    map['row_count'] = Variable<int>(rowCount);
    map['col_count'] = Variable<int>(colCount);
    return map;
  }

  DatasetTablesCompanion toCompanion(bool nullToAbsent) {
    return DatasetTablesCompanion(
      id: Value(id),
      datasetId: Value(datasetId),
      sheetNameOriginal: Value(sheetNameOriginal),
      sqlTableName: Value(sqlTableName),
      rowCount: Value(rowCount),
      colCount: Value(colCount),
    );
  }

  factory DatasetTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetTable(
      id: serializer.fromJson<int>(json['id']),
      datasetId: serializer.fromJson<int>(json['datasetId']),
      sheetNameOriginal: serializer.fromJson<String>(json['sheetNameOriginal']),
      sqlTableName: serializer.fromJson<String>(json['sqlTableName']),
      rowCount: serializer.fromJson<int>(json['rowCount']),
      colCount: serializer.fromJson<int>(json['colCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetId': serializer.toJson<int>(datasetId),
      'sheetNameOriginal': serializer.toJson<String>(sheetNameOriginal),
      'sqlTableName': serializer.toJson<String>(sqlTableName),
      'rowCount': serializer.toJson<int>(rowCount),
      'colCount': serializer.toJson<int>(colCount),
    };
  }

  DatasetTable copyWith(
          {int? id,
          int? datasetId,
          String? sheetNameOriginal,
          String? sqlTableName,
          int? rowCount,
          int? colCount}) =>
      DatasetTable(
        id: id ?? this.id,
        datasetId: datasetId ?? this.datasetId,
        sheetNameOriginal: sheetNameOriginal ?? this.sheetNameOriginal,
        sqlTableName: sqlTableName ?? this.sqlTableName,
        rowCount: rowCount ?? this.rowCount,
        colCount: colCount ?? this.colCount,
      );
  DatasetTable copyWithCompanion(DatasetTablesCompanion data) {
    return DatasetTable(
      id: data.id.present ? data.id.value : this.id,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      sheetNameOriginal: data.sheetNameOriginal.present
          ? data.sheetNameOriginal.value
          : this.sheetNameOriginal,
      sqlTableName: data.sqlTableName.present
          ? data.sqlTableName.value
          : this.sqlTableName,
      rowCount: data.rowCount.present ? data.rowCount.value : this.rowCount,
      colCount: data.colCount.present ? data.colCount.value : this.colCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetTable(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('sheetNameOriginal: $sheetNameOriginal, ')
          ..write('sqlTableName: $sqlTableName, ')
          ..write('rowCount: $rowCount, ')
          ..write('colCount: $colCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, datasetId, sheetNameOriginal, sqlTableName, rowCount, colCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetTable &&
          other.id == this.id &&
          other.datasetId == this.datasetId &&
          other.sheetNameOriginal == this.sheetNameOriginal &&
          other.sqlTableName == this.sqlTableName &&
          other.rowCount == this.rowCount &&
          other.colCount == this.colCount);
}

class DatasetTablesCompanion extends UpdateCompanion<DatasetTable> {
  final Value<int> id;
  final Value<int> datasetId;
  final Value<String> sheetNameOriginal;
  final Value<String> sqlTableName;
  final Value<int> rowCount;
  final Value<int> colCount;
  const DatasetTablesCompanion({
    this.id = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.sheetNameOriginal = const Value.absent(),
    this.sqlTableName = const Value.absent(),
    this.rowCount = const Value.absent(),
    this.colCount = const Value.absent(),
  });
  DatasetTablesCompanion.insert({
    this.id = const Value.absent(),
    required int datasetId,
    required String sheetNameOriginal,
    required String sqlTableName,
    required int rowCount,
    required int colCount,
  })  : datasetId = Value(datasetId),
        sheetNameOriginal = Value(sheetNameOriginal),
        sqlTableName = Value(sqlTableName),
        rowCount = Value(rowCount),
        colCount = Value(colCount);
  static Insertable<DatasetTable> custom({
    Expression<int>? id,
    Expression<int>? datasetId,
    Expression<String>? sheetNameOriginal,
    Expression<String>? sqlTableName,
    Expression<int>? rowCount,
    Expression<int>? colCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetId != null) 'dataset_id': datasetId,
      if (sheetNameOriginal != null) 'sheet_name_original': sheetNameOriginal,
      if (sqlTableName != null) 'sql_table_name': sqlTableName,
      if (rowCount != null) 'row_count': rowCount,
      if (colCount != null) 'col_count': colCount,
    });
  }

  DatasetTablesCompanion copyWith(
      {Value<int>? id,
      Value<int>? datasetId,
      Value<String>? sheetNameOriginal,
      Value<String>? sqlTableName,
      Value<int>? rowCount,
      Value<int>? colCount}) {
    return DatasetTablesCompanion(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      sheetNameOriginal: sheetNameOriginal ?? this.sheetNameOriginal,
      sqlTableName: sqlTableName ?? this.sqlTableName,
      rowCount: rowCount ?? this.rowCount,
      colCount: colCount ?? this.colCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetId.present) {
      map['dataset_id'] = Variable<int>(datasetId.value);
    }
    if (sheetNameOriginal.present) {
      map['sheet_name_original'] = Variable<String>(sheetNameOriginal.value);
    }
    if (sqlTableName.present) {
      map['sql_table_name'] = Variable<String>(sqlTableName.value);
    }
    if (rowCount.present) {
      map['row_count'] = Variable<int>(rowCount.value);
    }
    if (colCount.present) {
      map['col_count'] = Variable<int>(colCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetTablesCompanion(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('sheetNameOriginal: $sheetNameOriginal, ')
          ..write('sqlTableName: $sqlTableName, ')
          ..write('rowCount: $rowCount, ')
          ..write('colCount: $colCount')
          ..write(')'))
        .toString();
  }
}

class $DatasetColumnsTable extends DatasetColumns
    with TableInfo<$DatasetColumnsTable, DatasetColumn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetColumnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datasetTableIdMeta =
      const VerificationMeta('datasetTableId');
  @override
  late final GeneratedColumn<int> datasetTableId = GeneratedColumn<int>(
      'dataset_table_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES dataset_tables (id)'));
  static const VerificationMeta _originalNameMeta =
      const VerificationMeta('originalName');
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
      'original_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dbNameMeta = const VerificationMeta('dbName');
  @override
  late final GeneratedColumn<String> dbName = GeneratedColumn<String>(
      'db_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _declaredTypeMeta =
      const VerificationMeta('declaredType');
  @override
  late final GeneratedColumn<String> declaredType = GeneratedColumn<String>(
      'declared_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inferredTypeMeta =
      const VerificationMeta('inferredType');
  @override
  late final GeneratedColumn<String> inferredType = GeneratedColumn<String>(
      'inferred_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nullableMeta =
      const VerificationMeta('nullable');
  @override
  late final GeneratedColumn<bool> nullable = GeneratedColumn<bool>(
      'nullable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("nullable" IN (0, 1))'));
  static const VerificationMeta _statsJsonMeta =
      const VerificationMeta('statsJson');
  @override
  late final GeneratedColumn<String> statsJson = GeneratedColumn<String>(
      'stats_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        datasetTableId,
        originalName,
        dbName,
        declaredType,
        inferredType,
        nullable,
        statsJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_columns';
  @override
  VerificationContext validateIntegrity(Insertable<DatasetColumn> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_table_id')) {
      context.handle(
          _datasetTableIdMeta,
          datasetTableId.isAcceptableOrUnknown(
              data['dataset_table_id']!, _datasetTableIdMeta));
    } else if (isInserting) {
      context.missing(_datasetTableIdMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
          _originalNameMeta,
          originalName.isAcceptableOrUnknown(
              data['original_name']!, _originalNameMeta));
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('db_name')) {
      context.handle(_dbNameMeta,
          dbName.isAcceptableOrUnknown(data['db_name']!, _dbNameMeta));
    } else if (isInserting) {
      context.missing(_dbNameMeta);
    }
    if (data.containsKey('declared_type')) {
      context.handle(
          _declaredTypeMeta,
          declaredType.isAcceptableOrUnknown(
              data['declared_type']!, _declaredTypeMeta));
    } else if (isInserting) {
      context.missing(_declaredTypeMeta);
    }
    if (data.containsKey('inferred_type')) {
      context.handle(
          _inferredTypeMeta,
          inferredType.isAcceptableOrUnknown(
              data['inferred_type']!, _inferredTypeMeta));
    } else if (isInserting) {
      context.missing(_inferredTypeMeta);
    }
    if (data.containsKey('nullable')) {
      context.handle(_nullableMeta,
          nullable.isAcceptableOrUnknown(data['nullable']!, _nullableMeta));
    } else if (isInserting) {
      context.missing(_nullableMeta);
    }
    if (data.containsKey('stats_json')) {
      context.handle(_statsJsonMeta,
          statsJson.isAcceptableOrUnknown(data['stats_json']!, _statsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetColumn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetColumn(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datasetTableId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dataset_table_id'])!,
      originalName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_name'])!,
      dbName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}db_name'])!,
      declaredType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}declared_type'])!,
      inferredType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}inferred_type'])!,
      nullable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}nullable'])!,
      statsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stats_json']),
    );
  }

  @override
  $DatasetColumnsTable createAlias(String alias) {
    return $DatasetColumnsTable(attachedDatabase, alias);
  }
}

class DatasetColumn extends DataClass implements Insertable<DatasetColumn> {
  final int id;

  /// Foreign key to DatasetTables.id
  final int datasetTableId;

  /// Column name as found in the Excel header
  final String originalName;

  /// Sanitized SQL-safe column name
  final String dbName;

  /// Type selected/confirmed by user (TEXT, INTEGER, REAL, DATE, etc.)
  final String declaredType;

  /// Type inferred automatically by the system
  final String inferredType;

  /// Whether column allows null values
  final bool nullable;

  /// JSON containing statistics (min, max, distinctCount, etc.)
  final String? statsJson;
  const DatasetColumn(
      {required this.id,
      required this.datasetTableId,
      required this.originalName,
      required this.dbName,
      required this.declaredType,
      required this.inferredType,
      required this.nullable,
      this.statsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_table_id'] = Variable<int>(datasetTableId);
    map['original_name'] = Variable<String>(originalName);
    map['db_name'] = Variable<String>(dbName);
    map['declared_type'] = Variable<String>(declaredType);
    map['inferred_type'] = Variable<String>(inferredType);
    map['nullable'] = Variable<bool>(nullable);
    if (!nullToAbsent || statsJson != null) {
      map['stats_json'] = Variable<String>(statsJson);
    }
    return map;
  }

  DatasetColumnsCompanion toCompanion(bool nullToAbsent) {
    return DatasetColumnsCompanion(
      id: Value(id),
      datasetTableId: Value(datasetTableId),
      originalName: Value(originalName),
      dbName: Value(dbName),
      declaredType: Value(declaredType),
      inferredType: Value(inferredType),
      nullable: Value(nullable),
      statsJson: statsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(statsJson),
    );
  }

  factory DatasetColumn.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetColumn(
      id: serializer.fromJson<int>(json['id']),
      datasetTableId: serializer.fromJson<int>(json['datasetTableId']),
      originalName: serializer.fromJson<String>(json['originalName']),
      dbName: serializer.fromJson<String>(json['dbName']),
      declaredType: serializer.fromJson<String>(json['declaredType']),
      inferredType: serializer.fromJson<String>(json['inferredType']),
      nullable: serializer.fromJson<bool>(json['nullable']),
      statsJson: serializer.fromJson<String?>(json['statsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetTableId': serializer.toJson<int>(datasetTableId),
      'originalName': serializer.toJson<String>(originalName),
      'dbName': serializer.toJson<String>(dbName),
      'declaredType': serializer.toJson<String>(declaredType),
      'inferredType': serializer.toJson<String>(inferredType),
      'nullable': serializer.toJson<bool>(nullable),
      'statsJson': serializer.toJson<String?>(statsJson),
    };
  }

  DatasetColumn copyWith(
          {int? id,
          int? datasetTableId,
          String? originalName,
          String? dbName,
          String? declaredType,
          String? inferredType,
          bool? nullable,
          Value<String?> statsJson = const Value.absent()}) =>
      DatasetColumn(
        id: id ?? this.id,
        datasetTableId: datasetTableId ?? this.datasetTableId,
        originalName: originalName ?? this.originalName,
        dbName: dbName ?? this.dbName,
        declaredType: declaredType ?? this.declaredType,
        inferredType: inferredType ?? this.inferredType,
        nullable: nullable ?? this.nullable,
        statsJson: statsJson.present ? statsJson.value : this.statsJson,
      );
  DatasetColumn copyWithCompanion(DatasetColumnsCompanion data) {
    return DatasetColumn(
      id: data.id.present ? data.id.value : this.id,
      datasetTableId: data.datasetTableId.present
          ? data.datasetTableId.value
          : this.datasetTableId,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      dbName: data.dbName.present ? data.dbName.value : this.dbName,
      declaredType: data.declaredType.present
          ? data.declaredType.value
          : this.declaredType,
      inferredType: data.inferredType.present
          ? data.inferredType.value
          : this.inferredType,
      nullable: data.nullable.present ? data.nullable.value : this.nullable,
      statsJson: data.statsJson.present ? data.statsJson.value : this.statsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetColumn(')
          ..write('id: $id, ')
          ..write('datasetTableId: $datasetTableId, ')
          ..write('originalName: $originalName, ')
          ..write('dbName: $dbName, ')
          ..write('declaredType: $declaredType, ')
          ..write('inferredType: $inferredType, ')
          ..write('nullable: $nullable, ')
          ..write('statsJson: $statsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, datasetTableId, originalName, dbName,
      declaredType, inferredType, nullable, statsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetColumn &&
          other.id == this.id &&
          other.datasetTableId == this.datasetTableId &&
          other.originalName == this.originalName &&
          other.dbName == this.dbName &&
          other.declaredType == this.declaredType &&
          other.inferredType == this.inferredType &&
          other.nullable == this.nullable &&
          other.statsJson == this.statsJson);
}

class DatasetColumnsCompanion extends UpdateCompanion<DatasetColumn> {
  final Value<int> id;
  final Value<int> datasetTableId;
  final Value<String> originalName;
  final Value<String> dbName;
  final Value<String> declaredType;
  final Value<String> inferredType;
  final Value<bool> nullable;
  final Value<String?> statsJson;
  const DatasetColumnsCompanion({
    this.id = const Value.absent(),
    this.datasetTableId = const Value.absent(),
    this.originalName = const Value.absent(),
    this.dbName = const Value.absent(),
    this.declaredType = const Value.absent(),
    this.inferredType = const Value.absent(),
    this.nullable = const Value.absent(),
    this.statsJson = const Value.absent(),
  });
  DatasetColumnsCompanion.insert({
    this.id = const Value.absent(),
    required int datasetTableId,
    required String originalName,
    required String dbName,
    required String declaredType,
    required String inferredType,
    required bool nullable,
    this.statsJson = const Value.absent(),
  })  : datasetTableId = Value(datasetTableId),
        originalName = Value(originalName),
        dbName = Value(dbName),
        declaredType = Value(declaredType),
        inferredType = Value(inferredType),
        nullable = Value(nullable);
  static Insertable<DatasetColumn> custom({
    Expression<int>? id,
    Expression<int>? datasetTableId,
    Expression<String>? originalName,
    Expression<String>? dbName,
    Expression<String>? declaredType,
    Expression<String>? inferredType,
    Expression<bool>? nullable,
    Expression<String>? statsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetTableId != null) 'dataset_table_id': datasetTableId,
      if (originalName != null) 'original_name': originalName,
      if (dbName != null) 'db_name': dbName,
      if (declaredType != null) 'declared_type': declaredType,
      if (inferredType != null) 'inferred_type': inferredType,
      if (nullable != null) 'nullable': nullable,
      if (statsJson != null) 'stats_json': statsJson,
    });
  }

  DatasetColumnsCompanion copyWith(
      {Value<int>? id,
      Value<int>? datasetTableId,
      Value<String>? originalName,
      Value<String>? dbName,
      Value<String>? declaredType,
      Value<String>? inferredType,
      Value<bool>? nullable,
      Value<String?>? statsJson}) {
    return DatasetColumnsCompanion(
      id: id ?? this.id,
      datasetTableId: datasetTableId ?? this.datasetTableId,
      originalName: originalName ?? this.originalName,
      dbName: dbName ?? this.dbName,
      declaredType: declaredType ?? this.declaredType,
      inferredType: inferredType ?? this.inferredType,
      nullable: nullable ?? this.nullable,
      statsJson: statsJson ?? this.statsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetTableId.present) {
      map['dataset_table_id'] = Variable<int>(datasetTableId.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (dbName.present) {
      map['db_name'] = Variable<String>(dbName.value);
    }
    if (declaredType.present) {
      map['declared_type'] = Variable<String>(declaredType.value);
    }
    if (inferredType.present) {
      map['inferred_type'] = Variable<String>(inferredType.value);
    }
    if (nullable.present) {
      map['nullable'] = Variable<bool>(nullable.value);
    }
    if (statsJson.present) {
      map['stats_json'] = Variable<String>(statsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetColumnsCompanion(')
          ..write('id: $id, ')
          ..write('datasetTableId: $datasetTableId, ')
          ..write('originalName: $originalName, ')
          ..write('dbName: $dbName, ')
          ..write('declaredType: $declaredType, ')
          ..write('inferredType: $inferredType, ')
          ..write('nullable: $nullable, ')
          ..write('statsJson: $statsJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DatasetsTable datasets = $DatasetsTable(this);
  late final $DatasetTablesTable datasetTables = $DatasetTablesTable(this);
  late final $DatasetColumnsTable datasetColumns = $DatasetColumnsTable(this);
  late final DatasetsDao datasetsDao = DatasetsDao(this as AppDatabase);
  late final DatasetTablesDao datasetTablesDao =
      DatasetTablesDao(this as AppDatabase);
  late final DatasetColumnsDao datasetColumnsDao =
      DatasetColumnsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [datasets, datasetTables, datasetColumns];
}

typedef $$DatasetsTableCreateCompanionBuilder = DatasetsCompanion Function({
  Value<int> id,
  required String name,
  required String sourceFileName,
  Value<String?> sourceFileHash,
  required int createdAt,
  Value<int?> lastOpenedAt,
  Value<String?> uiStateJson,
});
typedef $$DatasetsTableUpdateCompanionBuilder = DatasetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> sourceFileName,
  Value<String?> sourceFileHash,
  Value<int> createdAt,
  Value<int?> lastOpenedAt,
  Value<String?> uiStateJson,
});

final class $$DatasetsTableReferences
    extends BaseReferences<_$AppDatabase, $DatasetsTable, Dataset> {
  $$DatasetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DatasetTablesTable, List<DatasetTable>>
      _datasetTablesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.datasetTables,
              aliasName: $_aliasNameGenerator(
                  db.datasets.id, db.datasetTables.datasetId));

  $$DatasetTablesTableProcessedTableManager get datasetTablesRefs {
    final manager = $$DatasetTablesTableTableManager($_db, $_db.datasetTables)
        .filter((f) => f.datasetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_datasetTablesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DatasetsTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetsTable> {
  $$DatasetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uiStateJson => $composableBuilder(
      column: $table.uiStateJson, builder: (column) => ColumnFilters(column));

  Expression<bool> datasetTablesRefs(
      Expression<bool> Function($$DatasetTablesTableFilterComposer f) f) {
    final $$DatasetTablesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.datasetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableFilterComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DatasetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetsTable> {
  $$DatasetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uiStateJson => $composableBuilder(
      column: $table.uiStateJson, builder: (column) => ColumnOrderings(column));
}

class $$DatasetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetsTable> {
  $$DatasetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName, builder: (column) => column);

  GeneratedColumn<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumn<String> get uiStateJson => $composableBuilder(
      column: $table.uiStateJson, builder: (column) => column);

  Expression<T> datasetTablesRefs<T extends Object>(
      Expression<T> Function($$DatasetTablesTableAnnotationComposer a) f) {
    final $$DatasetTablesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.datasetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableAnnotationComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DatasetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetsTable,
    Dataset,
    $$DatasetsTableFilterComposer,
    $$DatasetsTableOrderingComposer,
    $$DatasetsTableAnnotationComposer,
    $$DatasetsTableCreateCompanionBuilder,
    $$DatasetsTableUpdateCompanionBuilder,
    (Dataset, $$DatasetsTableReferences),
    Dataset,
    PrefetchHooks Function({bool datasetTablesRefs})> {
  $$DatasetsTableTableManager(_$AppDatabase db, $DatasetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> sourceFileName = const Value.absent(),
            Value<String?> sourceFileHash = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastOpenedAt = const Value.absent(),
            Value<String?> uiStateJson = const Value.absent(),
          }) =>
              DatasetsCompanion(
            id: id,
            name: name,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            createdAt: createdAt,
            lastOpenedAt: lastOpenedAt,
            uiStateJson: uiStateJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String sourceFileName,
            Value<String?> sourceFileHash = const Value.absent(),
            required int createdAt,
            Value<int?> lastOpenedAt = const Value.absent(),
            Value<String?> uiStateJson = const Value.absent(),
          }) =>
              DatasetsCompanion.insert(
            id: id,
            name: name,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            createdAt: createdAt,
            lastOpenedAt: lastOpenedAt,
            uiStateJson: uiStateJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DatasetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({datasetTablesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (datasetTablesRefs) db.datasetTables
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (datasetTablesRefs)
                    await $_getPrefetchedData<Dataset, $DatasetsTable,
                            DatasetTable>(
                        currentTable: table,
                        referencedTable: $$DatasetsTableReferences
                            ._datasetTablesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DatasetsTableReferences(db, table, p0)
                                .datasetTablesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.datasetId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DatasetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatasetsTable,
    Dataset,
    $$DatasetsTableFilterComposer,
    $$DatasetsTableOrderingComposer,
    $$DatasetsTableAnnotationComposer,
    $$DatasetsTableCreateCompanionBuilder,
    $$DatasetsTableUpdateCompanionBuilder,
    (Dataset, $$DatasetsTableReferences),
    Dataset,
    PrefetchHooks Function({bool datasetTablesRefs})>;
typedef $$DatasetTablesTableCreateCompanionBuilder = DatasetTablesCompanion
    Function({
  Value<int> id,
  required int datasetId,
  required String sheetNameOriginal,
  required String sqlTableName,
  required int rowCount,
  required int colCount,
});
typedef $$DatasetTablesTableUpdateCompanionBuilder = DatasetTablesCompanion
    Function({
  Value<int> id,
  Value<int> datasetId,
  Value<String> sheetNameOriginal,
  Value<String> sqlTableName,
  Value<int> rowCount,
  Value<int> colCount,
});

final class $$DatasetTablesTableReferences
    extends BaseReferences<_$AppDatabase, $DatasetTablesTable, DatasetTable> {
  $$DatasetTablesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DatasetsTable _datasetIdTable(_$AppDatabase db) =>
      db.datasets.createAlias(
          $_aliasNameGenerator(db.datasetTables.datasetId, db.datasets.id));

  $$DatasetsTableProcessedTableManager get datasetId {
    final $_column = $_itemColumn<int>('dataset_id')!;

    final manager = $$DatasetsTableTableManager($_db, $_db.datasets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_datasetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DatasetColumnsTable, List<DatasetColumn>>
      _datasetColumnsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.datasetColumns,
              aliasName: $_aliasNameGenerator(
                  db.datasetTables.id, db.datasetColumns.datasetTableId));

  $$DatasetColumnsTableProcessedTableManager get datasetColumnsRefs {
    final manager = $$DatasetColumnsTableTableManager($_db, $_db.datasetColumns)
        .filter((f) => f.datasetTableId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_datasetColumnsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DatasetTablesTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetTablesTable> {
  $$DatasetTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sheetNameOriginal => $composableBuilder(
      column: $table.sheetNameOriginal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sqlTableName => $composableBuilder(
      column: $table.sqlTableName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rowCount => $composableBuilder(
      column: $table.rowCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colCount => $composableBuilder(
      column: $table.colCount, builder: (column) => ColumnFilters(column));

  $$DatasetsTableFilterComposer get datasetId {
    final $$DatasetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableFilterComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> datasetColumnsRefs(
      Expression<bool> Function($$DatasetColumnsTableFilterComposer f) f) {
    final $$DatasetColumnsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetColumns,
        getReferencedColumn: (t) => t.datasetTableId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetColumnsTableFilterComposer(
              $db: $db,
              $table: $db.datasetColumns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DatasetTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetTablesTable> {
  $$DatasetTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sheetNameOriginal => $composableBuilder(
      column: $table.sheetNameOriginal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sqlTableName => $composableBuilder(
      column: $table.sqlTableName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rowCount => $composableBuilder(
      column: $table.rowCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colCount => $composableBuilder(
      column: $table.colCount, builder: (column) => ColumnOrderings(column));

  $$DatasetsTableOrderingComposer get datasetId {
    final $$DatasetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableOrderingComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetTablesTable> {
  $$DatasetTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sheetNameOriginal => $composableBuilder(
      column: $table.sheetNameOriginal, builder: (column) => column);

  GeneratedColumn<String> get sqlTableName => $composableBuilder(
      column: $table.sqlTableName, builder: (column) => column);

  GeneratedColumn<int> get rowCount =>
      $composableBuilder(column: $table.rowCount, builder: (column) => column);

  GeneratedColumn<int> get colCount =>
      $composableBuilder(column: $table.colCount, builder: (column) => column);

  $$DatasetsTableAnnotationComposer get datasetId {
    final $$DatasetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableAnnotationComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> datasetColumnsRefs<T extends Object>(
      Expression<T> Function($$DatasetColumnsTableAnnotationComposer a) f) {
    final $$DatasetColumnsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetColumns,
        getReferencedColumn: (t) => t.datasetTableId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetColumnsTableAnnotationComposer(
              $db: $db,
              $table: $db.datasetColumns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DatasetTablesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetTablesTable,
    DatasetTable,
    $$DatasetTablesTableFilterComposer,
    $$DatasetTablesTableOrderingComposer,
    $$DatasetTablesTableAnnotationComposer,
    $$DatasetTablesTableCreateCompanionBuilder,
    $$DatasetTablesTableUpdateCompanionBuilder,
    (DatasetTable, $$DatasetTablesTableReferences),
    DatasetTable,
    PrefetchHooks Function({bool datasetId, bool datasetColumnsRefs})> {
  $$DatasetTablesTableTableManager(_$AppDatabase db, $DatasetTablesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datasetId = const Value.absent(),
            Value<String> sheetNameOriginal = const Value.absent(),
            Value<String> sqlTableName = const Value.absent(),
            Value<int> rowCount = const Value.absent(),
            Value<int> colCount = const Value.absent(),
          }) =>
              DatasetTablesCompanion(
            id: id,
            datasetId: datasetId,
            sheetNameOriginal: sheetNameOriginal,
            sqlTableName: sqlTableName,
            rowCount: rowCount,
            colCount: colCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datasetId,
            required String sheetNameOriginal,
            required String sqlTableName,
            required int rowCount,
            required int colCount,
          }) =>
              DatasetTablesCompanion.insert(
            id: id,
            datasetId: datasetId,
            sheetNameOriginal: sheetNameOriginal,
            sqlTableName: sqlTableName,
            rowCount: rowCount,
            colCount: colCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DatasetTablesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {datasetId = false, datasetColumnsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (datasetColumnsRefs) db.datasetColumns
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (datasetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.datasetId,
                    referencedTable:
                        $$DatasetTablesTableReferences._datasetIdTable(db),
                    referencedColumn:
                        $$DatasetTablesTableReferences._datasetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (datasetColumnsRefs)
                    await $_getPrefetchedData<DatasetTable, $DatasetTablesTable,
                            DatasetColumn>(
                        currentTable: table,
                        referencedTable: $$DatasetTablesTableReferences
                            ._datasetColumnsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DatasetTablesTableReferences(db, table, p0)
                                .datasetColumnsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.datasetTableId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DatasetTablesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatasetTablesTable,
    DatasetTable,
    $$DatasetTablesTableFilterComposer,
    $$DatasetTablesTableOrderingComposer,
    $$DatasetTablesTableAnnotationComposer,
    $$DatasetTablesTableCreateCompanionBuilder,
    $$DatasetTablesTableUpdateCompanionBuilder,
    (DatasetTable, $$DatasetTablesTableReferences),
    DatasetTable,
    PrefetchHooks Function({bool datasetId, bool datasetColumnsRefs})>;
typedef $$DatasetColumnsTableCreateCompanionBuilder = DatasetColumnsCompanion
    Function({
  Value<int> id,
  required int datasetTableId,
  required String originalName,
  required String dbName,
  required String declaredType,
  required String inferredType,
  required bool nullable,
  Value<String?> statsJson,
});
typedef $$DatasetColumnsTableUpdateCompanionBuilder = DatasetColumnsCompanion
    Function({
  Value<int> id,
  Value<int> datasetTableId,
  Value<String> originalName,
  Value<String> dbName,
  Value<String> declaredType,
  Value<String> inferredType,
  Value<bool> nullable,
  Value<String?> statsJson,
});

final class $$DatasetColumnsTableReferences
    extends BaseReferences<_$AppDatabase, $DatasetColumnsTable, DatasetColumn> {
  $$DatasetColumnsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DatasetTablesTable _datasetTableIdTable(_$AppDatabase db) =>
      db.datasetTables.createAlias($_aliasNameGenerator(
          db.datasetColumns.datasetTableId, db.datasetTables.id));

  $$DatasetTablesTableProcessedTableManager get datasetTableId {
    final $_column = $_itemColumn<int>('dataset_table_id')!;

    final manager = $$DatasetTablesTableTableManager($_db, $_db.datasetTables)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_datasetTableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DatasetColumnsTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetColumnsTable> {
  $$DatasetColumnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalName => $composableBuilder(
      column: $table.originalName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dbName => $composableBuilder(
      column: $table.dbName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get declaredType => $composableBuilder(
      column: $table.declaredType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inferredType => $composableBuilder(
      column: $table.inferredType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get nullable => $composableBuilder(
      column: $table.nullable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statsJson => $composableBuilder(
      column: $table.statsJson, builder: (column) => ColumnFilters(column));

  $$DatasetTablesTableFilterComposer get datasetTableId {
    final $$DatasetTablesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetTableId,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableFilterComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetColumnsTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetColumnsTable> {
  $$DatasetColumnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalName => $composableBuilder(
      column: $table.originalName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dbName => $composableBuilder(
      column: $table.dbName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get declaredType => $composableBuilder(
      column: $table.declaredType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inferredType => $composableBuilder(
      column: $table.inferredType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get nullable => $composableBuilder(
      column: $table.nullable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statsJson => $composableBuilder(
      column: $table.statsJson, builder: (column) => ColumnOrderings(column));

  $$DatasetTablesTableOrderingComposer get datasetTableId {
    final $$DatasetTablesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetTableId,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableOrderingComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetColumnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetColumnsTable> {
  $$DatasetColumnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
      column: $table.originalName, builder: (column) => column);

  GeneratedColumn<String> get dbName =>
      $composableBuilder(column: $table.dbName, builder: (column) => column);

  GeneratedColumn<String> get declaredType => $composableBuilder(
      column: $table.declaredType, builder: (column) => column);

  GeneratedColumn<String> get inferredType => $composableBuilder(
      column: $table.inferredType, builder: (column) => column);

  GeneratedColumn<bool> get nullable =>
      $composableBuilder(column: $table.nullable, builder: (column) => column);

  GeneratedColumn<String> get statsJson =>
      $composableBuilder(column: $table.statsJson, builder: (column) => column);

  $$DatasetTablesTableAnnotationComposer get datasetTableId {
    final $$DatasetTablesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetTableId,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableAnnotationComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetColumnsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetColumnsTable,
    DatasetColumn,
    $$DatasetColumnsTableFilterComposer,
    $$DatasetColumnsTableOrderingComposer,
    $$DatasetColumnsTableAnnotationComposer,
    $$DatasetColumnsTableCreateCompanionBuilder,
    $$DatasetColumnsTableUpdateCompanionBuilder,
    (DatasetColumn, $$DatasetColumnsTableReferences),
    DatasetColumn,
    PrefetchHooks Function({bool datasetTableId})> {
  $$DatasetColumnsTableTableManager(
      _$AppDatabase db, $DatasetColumnsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetColumnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetColumnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetColumnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datasetTableId = const Value.absent(),
            Value<String> originalName = const Value.absent(),
            Value<String> dbName = const Value.absent(),
            Value<String> declaredType = const Value.absent(),
            Value<String> inferredType = const Value.absent(),
            Value<bool> nullable = const Value.absent(),
            Value<String?> statsJson = const Value.absent(),
          }) =>
              DatasetColumnsCompanion(
            id: id,
            datasetTableId: datasetTableId,
            originalName: originalName,
            dbName: dbName,
            declaredType: declaredType,
            inferredType: inferredType,
            nullable: nullable,
            statsJson: statsJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datasetTableId,
            required String originalName,
            required String dbName,
            required String declaredType,
            required String inferredType,
            required bool nullable,
            Value<String?> statsJson = const Value.absent(),
          }) =>
              DatasetColumnsCompanion.insert(
            id: id,
            datasetTableId: datasetTableId,
            originalName: originalName,
            dbName: dbName,
            declaredType: declaredType,
            inferredType: inferredType,
            nullable: nullable,
            statsJson: statsJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DatasetColumnsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({datasetTableId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (datasetTableId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.datasetTableId,
                    referencedTable: $$DatasetColumnsTableReferences
                        ._datasetTableIdTable(db),
                    referencedColumn: $$DatasetColumnsTableReferences
                        ._datasetTableIdTable(db)
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
        ));
}

typedef $$DatasetColumnsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatasetColumnsTable,
    DatasetColumn,
    $$DatasetColumnsTableFilterComposer,
    $$DatasetColumnsTableOrderingComposer,
    $$DatasetColumnsTableAnnotationComposer,
    $$DatasetColumnsTableCreateCompanionBuilder,
    $$DatasetColumnsTableUpdateCompanionBuilder,
    (DatasetColumn, $$DatasetColumnsTableReferences),
    DatasetColumn,
    PrefetchHooks Function({bool datasetTableId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db, _db.datasets);
  $$DatasetTablesTableTableManager get datasetTables =>
      $$DatasetTablesTableTableManager(_db, _db.datasetTables);
  $$DatasetColumnsTableTableManager get datasetColumns =>
      $$DatasetColumnsTableTableManager(_db, _db.datasetColumns);
}
