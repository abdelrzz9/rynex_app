import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'tables/drawing_elements_table.dart';
import '../../dao/drawing_element_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [DrawingElementsTable],
  daos: [DrawingElementDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _productionExecutor());

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes();
      },
      beforeOpen: (OpenedDatabase details) async {
        await customStatement('PRAGMA journal_mode = WAL;');
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_elements_zindex '
      'ON drawing_elements (z_index ASC);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stroke_bounds '
      'ON drawing_elements '
      '(stroke_min_x, stroke_max_x, stroke_min_y, stroke_max_y) '
      'WHERE type = \'stroke\';',
    );
  }
}

QueryExecutor _productionExecutor() {
  return LazyDatabase(() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbDir.path, 'drawing_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

QueryExecutor inMemoryExecutor() => NativeDatabase.memory();
