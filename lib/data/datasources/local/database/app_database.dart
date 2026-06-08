import 'dart:async';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../../domain/entities/drawing_account_summary.dart';

/// Local SQLite database used by the drawing data layer.
///
/// This app is intentionally offline-first: all drawing elements are persisted
/// to a SQLite database in the app documents directory. No external backend is
/// required for creating, reading, updating, or deleting drawings.
class AppDatabase {
  AppDatabase([FutureOr<Database>? database])
    : _database = Future.value(database ?? _openProductionDatabase());

  static AppDatabase? _instance;

  static AppDatabase get instance => _instance ??= AppDatabase();

  final Future<Database> _database;
  int _activeAccountNumber = 1;

  final StreamController<List<DrawingElementsTableData>> _changes =
      StreamController<List<DrawingElementsTableData>>.broadcast();

  int get activeAccountNumber => _activeAccountNumber;

  Future<void> useAccount(int accountNumber) async {
    if (accountNumber < 1) {
      throw ArgumentError.value(
        accountNumber,
        'accountNumber',
        'Account number must be positive.',
      );
    }
    if (_activeAccountNumber == accountNumber) return;

    _activeAccountNumber = accountNumber;
    await _emitChanges();
  }

  Future<List<DrawingElementsTableData>> loadElements({
    int? accountNumber,
  }) async {
    final db = await _readyDatabase();
    final result = db.select(
      'SELECT * FROM drawing_elements '
      'WHERE account_number = ? '
      'ORDER BY z_index ASC;',
      [accountNumber ?? _activeAccountNumber],
    );
    return result.map(_rowToElement).toList(growable: false);
  }

  Future<List<DrawingAccountSummary>> loadAccountSummaries() async {
    final db = await _readyDatabase();
    final result = db.select(
      'SELECT account_number, color, COUNT(*) AS element_count '
      'FROM drawing_elements '
      'GROUP BY account_number, color '
      'ORDER BY account_number ASC;',
    );

    final summaries = <int, DrawingAccountSummary>{};
    for (final row in result) {
      final accountNumber = row['account_number'] as int;
      final color = row['color'] as int;
      final elementCount = row['element_count'] as int;
      final current = summaries[accountNumber] ??
          DrawingAccountSummary(accountNumber: accountNumber);
      summaries[accountNumber] = current.addColorCount(color, elementCount);
    }

    return summaries.values.toList(growable: false);
  }

  Stream<List<DrawingElementsTableData>> watchElements() async* {
    yield await loadElements();
    yield* _changes.stream;
  }

  Future<bool> containsElement(String id, {int? accountNumber}) async {
    final db = await _readyDatabase();
    final result = db.select(
      'SELECT 1 FROM drawing_elements '
      'WHERE account_number = ? AND id = ? '
      'LIMIT 1;',
      [accountNumber ?? _activeAccountNumber, id],
    );
    return result.isNotEmpty;
  }

  Future<DrawingElementsTableData?> elementById(
    String id, {
    int? accountNumber,
  }) async {
    final db = await _readyDatabase();
    final result = db.select(
      'SELECT * FROM drawing_elements '
      'WHERE account_number = ? AND id = ? '
      'LIMIT 1;',
      [accountNumber ?? _activeAccountNumber, id],
    );
    if (result.isEmpty) return null;
    return _rowToElement(result.first);
  }

  Future<void> insertElement(DrawingElementsTableData element) async {
    final db = await _readyDatabase();
    final scopedElement = element.copyWith(accountNumber: _activeAccountNumber);
    final statement = db.prepare(_insertSql);
    try {
      statement.execute(_elementParameters(scopedElement));
    } finally {
      statement.dispose();
    }
    await _emitChanges();
  }

  Future<void> upsertElement(DrawingElementsTableData element) async {
    final db = await _readyDatabase();
    final scopedElement = element.copyWith(accountNumber: _activeAccountNumber);
    final statement = db.prepare('$_insertSql $_upsertConflictSql');
    try {
      statement.execute(_elementParameters(scopedElement));
    } finally {
      statement.dispose();
    }
    await _emitChanges();
  }

  Future<bool> updateElement(DrawingElementsTableData element) async {
    final db = await _readyDatabase();
    final scopedElement = element.copyWith(accountNumber: _activeAccountNumber);
    final statement = db.prepare(_updateSql);
    try {
      statement.execute([
        ..._updateParameters(scopedElement),
        scopedElement.accountNumber,
        scopedElement.id,
      ]);
    } finally {
      statement.dispose();
    }

    final updated = db.updatedRows > 0;
    if (updated) {
      await _emitChanges();
    }
    return updated;
  }

  Future<bool> patchElement(
    String id,
    DrawingElementsTableCompanion companion,
  ) async {
    final existing = await elementById(id);
    if (existing == null) return false;

    final updated = await updateElement(companion.applyTo(existing));
    return updated;
  }

  Future<int> deleteElement(String id) async {
    final db = await _readyDatabase();
    db.execute(
      'DELETE FROM drawing_elements WHERE account_number = ? AND id = ?;',
      [_activeAccountNumber, id],
    );
    final deleted = db.updatedRows;
    if (deleted > 0) {
      await _emitChanges();
    }
    return deleted;
  }

  Future<int> clearElements() async {
    final db = await _readyDatabase();
    db.execute(
      'DELETE FROM drawing_elements WHERE account_number = ?;',
      [_activeAccountNumber],
    );
    final deleted = db.updatedRows;
    if (deleted > 0) {
      await _emitChanges();
    }
    return deleted;
  }

  Future<void> close() async {
    final db = await _database;
    db.dispose();
    await _changes.close();
  }

  Future<Database> _readyDatabase() async {
    final db = await _database;
    _configureDatabase(db);
    return db;
  }

  Future<void> _emitChanges() async {
    if (!_changes.isClosed) {
      _changes.add(await loadElements());
    }
  }

  static Future<Database> _openProductionDatabase() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(dbDir.path, 'drawing_app.sqlite');
    return sqlite3.open(dbPath);
  }

  static void _configureDatabase(Database db) {
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute(_createTableSql);
    _ensureAccountNumberColumn(db);
    db.execute(_createAccountIndexSql);
    db.execute(_createZIndexSql);
    db.execute(_createStrokeBoundsSql);
  }

  static void _ensureAccountNumberColumn(Database db) {
    final columns = db.select('PRAGMA table_info(drawing_elements);');
    final hasAccountNumber = columns.any(
      (column) => column['name'] == 'account_number',
    );
    if (!hasAccountNumber) {
      db.execute(
        'ALTER TABLE drawing_elements '
        'ADD COLUMN account_number INTEGER NOT NULL DEFAULT 1;',
      );
    }
  }

  static DrawingElementsTableData _rowToElement(Row row) {
    return DrawingElementsTableData(
      accountNumber: row['account_number'] as int,
      id: row['id'] as String,
      type: row['type'] as String,
      color: row['color'] as int,
      strokeWidth: (row['stroke_width'] as num).toDouble(),
      positionX: (row['position_x'] as num).toDouble(),
      positionY: (row['position_y'] as num).toDouble(),
      zIndex: row['z_index'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      geometryJson: row['geometry_json'] as String,
      rectWidth: _nullableDouble(row['rect_width']),
      rectHeight: _nullableDouble(row['rect_height']),
      lineEndX: _nullableDouble(row['line_end_x']),
      lineEndY: _nullableDouble(row['line_end_y']),
      strokeMinX: _nullableDouble(row['stroke_min_x']),
      strokeMinY: _nullableDouble(row['stroke_min_y']),
      strokeMaxX: _nullableDouble(row['stroke_max_x']),
      strokeMaxY: _nullableDouble(row['stroke_max_y']),
    );
  }

  static double? _nullableDouble(Object? value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }

  static List<Object?> _elementParameters(DrawingElementsTableData element) {
    return [
      element.accountNumber,
      element.id,
      element.type,
      element.color,
      element.strokeWidth,
      element.positionX,
      element.positionY,
      element.zIndex,
      element.createdAt.toUtc().millisecondsSinceEpoch,
      element.geometryJson,
      element.rectWidth,
      element.rectHeight,
      element.lineEndX,
      element.lineEndY,
      element.strokeMinX,
      element.strokeMinY,
      element.strokeMaxX,
      element.strokeMaxY,
    ];
  }

  static List<Object?> _updateParameters(DrawingElementsTableData element) {
    return _elementParameters(element).sublist(2);
  }
}

Database inMemoryExecutor() => sqlite3.openInMemory();

/// Row model for the drawing_elements table.
class DrawingElementsTableData {
  const DrawingElementsTableData({
    this.accountNumber = 1,
    required this.id,
    required this.type,
    required this.color,
    required this.strokeWidth,
    required this.positionX,
    required this.positionY,
    required this.zIndex,
    required this.createdAt,
    required this.geometryJson,
    this.rectWidth,
    this.rectHeight,
    this.lineEndX,
    this.lineEndY,
    this.strokeMinX,
    this.strokeMinY,
    this.strokeMaxX,
    this.strokeMaxY,
  });

  final int accountNumber;
  final String id;
  final String type;
  final int color;
  final double strokeWidth;
  final double positionX;
  final double positionY;
  final int zIndex;
  final DateTime createdAt;
  final String geometryJson;
  final double? rectWidth;
  final double? rectHeight;
  final double? lineEndX;
  final double? lineEndY;
  final double? strokeMinX;
  final double? strokeMinY;
  final double? strokeMaxX;
  final double? strokeMaxY;

  DrawingElementsTableData copyWith({
    int? accountNumber,
    String? id,
    String? type,
    int? color,
    double? strokeWidth,
    double? positionX,
    double? positionY,
    int? zIndex,
    DateTime? createdAt,
    String? geometryJson,
    Value<double?> rectWidth = const Value.absent(),
    Value<double?> rectHeight = const Value.absent(),
    Value<double?> lineEndX = const Value.absent(),
    Value<double?> lineEndY = const Value.absent(),
    Value<double?> strokeMinX = const Value.absent(),
    Value<double?> strokeMinY = const Value.absent(),
    Value<double?> strokeMaxX = const Value.absent(),
    Value<double?> strokeMaxY = const Value.absent(),
  }) {
    return DrawingElementsTableData(
      accountNumber: accountNumber ?? this.accountNumber,
      id: id ?? this.id,
      type: type ?? this.type,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      geometryJson: geometryJson ?? this.geometryJson,
      rectWidth: rectWidth.present ? rectWidth.value : this.rectWidth,
      rectHeight: rectHeight.present ? rectHeight.value : this.rectHeight,
      lineEndX: lineEndX.present ? lineEndX.value : this.lineEndX,
      lineEndY: lineEndY.present ? lineEndY.value : this.lineEndY,
      strokeMinX: strokeMinX.present ? strokeMinX.value : this.strokeMinX,
      strokeMinY: strokeMinY.present ? strokeMinY.value : this.strokeMinY,
      strokeMaxX: strokeMaxX.present ? strokeMaxX.value : this.strokeMaxX,
      strokeMaxY: strokeMaxY.present ? strokeMaxY.value : this.strokeMaxY,
    );
  }
}

/// Mutable companion-style value object used for inserts and updates.
class DrawingElementsTableCompanion {
  const DrawingElementsTableCompanion({
    this.accountNumber = const Value.absent(),
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.color = const Value.absent(),
    this.strokeWidth = const Value.absent(),
    this.positionX = const Value.absent(),
    this.positionY = const Value.absent(),
    this.zIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.geometryJson = const Value.absent(),
    this.rectWidth = const Value.absent(),
    this.rectHeight = const Value.absent(),
    this.lineEndX = const Value.absent(),
    this.lineEndY = const Value.absent(),
    this.strokeMinX = const Value.absent(),
    this.strokeMinY = const Value.absent(),
    this.strokeMaxX = const Value.absent(),
    this.strokeMaxY = const Value.absent(),
  });

  final Value<int> accountNumber;
  final Value<String> id;
  final Value<String> type;
  final Value<int> color;
  final Value<double> strokeWidth;
  final Value<double> positionX;
  final Value<double> positionY;
  final Value<int> zIndex;
  final Value<DateTime> createdAt;
  final Value<String> geometryJson;
  final Value<double?> rectWidth;
  final Value<double?> rectHeight;
  final Value<double?> lineEndX;
  final Value<double?> lineEndY;
  final Value<double?> strokeMinX;
  final Value<double?> strokeMinY;
  final Value<double?> strokeMaxX;
  final Value<double?> strokeMaxY;

  DrawingElementsTableData toData() {
    return DrawingElementsTableData(
      accountNumber: accountNumber.present ? accountNumber.value : 1,
      id: _required(id, 'id'),
      type: _required(type, 'type'),
      color: _required(color, 'color'),
      strokeWidth: _required(strokeWidth, 'strokeWidth'),
      positionX: _required(positionX, 'positionX'),
      positionY: _required(positionY, 'positionY'),
      zIndex: zIndex.present ? zIndex.value : 0,
      createdAt: createdAt.present ? createdAt.value : DateTime.now().toUtc(),
      geometryJson: _required(geometryJson, 'geometryJson'),
      rectWidth: rectWidth.present ? rectWidth.value : null,
      rectHeight: rectHeight.present ? rectHeight.value : null,
      lineEndX: lineEndX.present ? lineEndX.value : null,
      lineEndY: lineEndY.present ? lineEndY.value : null,
      strokeMinX: strokeMinX.present ? strokeMinX.value : null,
      strokeMinY: strokeMinY.present ? strokeMinY.value : null,
      strokeMaxX: strokeMaxX.present ? strokeMaxX.value : null,
      strokeMaxY: strokeMaxY.present ? strokeMaxY.value : null,
    );
  }

  DrawingElementsTableData applyTo(DrawingElementsTableData existing) {
    return existing.copyWith(
      accountNumber: accountNumber.present
          ? accountNumber.value
          : existing.accountNumber,
      id: id.present ? id.value : existing.id,
      type: type.present ? type.value : existing.type,
      color: color.present ? color.value : existing.color,
      strokeWidth: strokeWidth.present ? strokeWidth.value : existing.strokeWidth,
      positionX: positionX.present ? positionX.value : existing.positionX,
      positionY: positionY.present ? positionY.value : existing.positionY,
      zIndex: zIndex.present ? zIndex.value : existing.zIndex,
      createdAt: createdAt.present ? createdAt.value : existing.createdAt,
      geometryJson: geometryJson.present ? geometryJson.value : existing.geometryJson,
      rectWidth: rectWidth,
      rectHeight: rectHeight,
      lineEndX: lineEndX,
      lineEndY: lineEndY,
      strokeMinX: strokeMinX,
      strokeMinY: strokeMinY,
      strokeMaxX: strokeMaxX,
      strokeMaxY: strokeMaxY,
    );
  }

  DrawingElementsTableCompanion copyWith({
    Value<int>? accountNumber,
    Value<String>? id,
    Value<String>? type,
    Value<int>? color,
    Value<double>? strokeWidth,
    Value<double>? positionX,
    Value<double>? positionY,
    Value<int>? zIndex,
    Value<DateTime>? createdAt,
    Value<String>? geometryJson,
    Value<double?>? rectWidth,
    Value<double?>? rectHeight,
    Value<double?>? lineEndX,
    Value<double?>? lineEndY,
    Value<double?>? strokeMinX,
    Value<double?>? strokeMinY,
    Value<double?>? strokeMaxX,
    Value<double?>? strokeMaxY,
  }) {
    return DrawingElementsTableCompanion(
      accountNumber: accountNumber ?? this.accountNumber,
      id: id ?? this.id,
      type: type ?? this.type,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      geometryJson: geometryJson ?? this.geometryJson,
      rectWidth: rectWidth ?? this.rectWidth,
      rectHeight: rectHeight ?? this.rectHeight,
      lineEndX: lineEndX ?? this.lineEndX,
      lineEndY: lineEndY ?? this.lineEndY,
      strokeMinX: strokeMinX ?? this.strokeMinX,
      strokeMinY: strokeMinY ?? this.strokeMinY,
      strokeMaxX: strokeMaxX ?? this.strokeMaxX,
      strokeMaxY: strokeMaxY ?? this.strokeMaxY,
    );
  }

  static T _required<T>(Value<T> value, String fieldName) {
    if (!value.present) {
      throw StateError('Missing required drawing element field: $fieldName');
    }
    return value.value;
  }
}

const String _createTableSql = '''
CREATE TABLE IF NOT EXISTS drawing_elements (
  account_number INTEGER NOT NULL DEFAULT 1,
  id TEXT NOT NULL PRIMARY KEY,
  type TEXT NOT NULL,
  color INTEGER NOT NULL,
  stroke_width REAL NOT NULL,
  position_x REAL NOT NULL,
  position_y REAL NOT NULL,
  z_index INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  geometry_json TEXT NOT NULL,
  rect_width REAL,
  rect_height REAL,
  line_end_x REAL,
  line_end_y REAL,
  stroke_min_x REAL,
  stroke_min_y REAL,
  stroke_max_x REAL,
  stroke_max_y REAL
);
''';

const String _createAccountIndexSql = '''
CREATE INDEX IF NOT EXISTS idx_elements_account
ON drawing_elements (account_number ASC);
''';

const String _createZIndexSql = '''
CREATE INDEX IF NOT EXISTS idx_elements_account_zindex
ON drawing_elements (account_number ASC, z_index ASC);
''';

const String _createStrokeBoundsSql = '''
CREATE INDEX IF NOT EXISTS idx_stroke_bounds
ON drawing_elements (
  account_number,
  stroke_min_x,
  stroke_max_x,
  stroke_min_y,
  stroke_max_y
)
WHERE type = 'stroke';
''';

const String _insertSql = '''
INSERT INTO drawing_elements (
  account_number,
  id,
  type,
  color,
  stroke_width,
  position_x,
  position_y,
  z_index,
  created_at,
  geometry_json,
  rect_width,
  rect_height,
  line_end_x,
  line_end_y,
  stroke_min_x,
  stroke_min_y,
  stroke_max_x,
  stroke_max_y
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''';

const String _upsertConflictSql = '''
ON CONFLICT(id) DO UPDATE SET
  account_number = excluded.account_number,
  type = excluded.type,
  color = excluded.color,
  stroke_width = excluded.stroke_width,
  position_x = excluded.position_x,
  position_y = excluded.position_y,
  z_index = excluded.z_index,
  created_at = excluded.created_at,
  geometry_json = excluded.geometry_json,
  rect_width = excluded.rect_width,
  rect_height = excluded.rect_height,
  line_end_x = excluded.line_end_x,
  line_end_y = excluded.line_end_y,
  stroke_min_x = excluded.stroke_min_x,
  stroke_min_y = excluded.stroke_min_y,
  stroke_max_x = excluded.stroke_max_x,
  stroke_max_y = excluded.stroke_max_y;
''';

const String _updateSql = '''
UPDATE drawing_elements SET
  type = ?,
  color = ?,
  stroke_width = ?,
  position_x = ?,
  position_y = ?,
  z_index = ?,
  created_at = ?,
  geometry_json = ?,
  rect_width = ?,
  rect_height = ?,
  line_end_x = ?,
  line_end_y = ?,
  stroke_min_x = ?,
  stroke_min_y = ?,
  stroke_max_x = ?,
  stroke_max_y = ?
WHERE account_number = ? AND id = ?;
''';
