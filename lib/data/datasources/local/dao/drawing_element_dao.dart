import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/drawing_elements_table.dart';

part 'drawing_element_dao.g.dart';

@DriftAccessor(tables: [DrawingElementsTable])
class DrawingElementDao extends DatabaseAccessor<AppDatabase>
    with _$DrawingElementDaoMixin {
  DrawingElementDao(super.db);

  Stream<List<DrawingElementsTableData>> watchAll() {
    return (select(drawingElementsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.zIndex)]))
        .watch();
  }

  Future<List<DrawingElementsTableData>> loadAll() {
    return (select(drawingElementsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.zIndex)]))
        .get();
  }

  Future<DrawingElementsTableData?> findById(String id) {
    return (select(drawingElementsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DrawingElementsTableData>> loadInViewport({
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
  }) {
    return (select(drawingElementsTable)
          ..where((t) =>
              t.type.equals('rect') |
              t.type.equals('line') |
              (t.type.equals('stroke') &
                  t.strokeMaxX.isBiggerOrEqualValue(minX) &
                  t.strokeMinX.isSmallerOrEqualValue(maxX) &
                  t.strokeMaxY.isBiggerOrEqualValue(minY) &
                  t.strokeMinY.isSmallerOrEqualValue(maxY)))
          ..orderBy([(t) => OrderingTerm.asc(t.zIndex)]))
        .get();
  }

  Future<void> insertElement(DrawingElementsTableCompanion companion) {
    return into(drawingElementsTable).insert(companion);
  }

  Future<void> upsertElement(DrawingElementsTableCompanion companion) {
    return into(drawingElementsTable).insertOnConflictUpdate(companion);
  }

  Future<bool> updateElement(DrawingElementsTableCompanion companion) {
    return update(drawingElementsTable).replace(companion);
  }

  Future<void> updateAll(List<DrawingElementsTableCompanion> companions) {
    return transaction(() async {
      final batch = db.batch();
      for (final companion in companions) {
        batch.update(
          drawingElementsTable,
          companion,
          where: (t) => t.id.equals(companion.id.value),
        );
      }
      await batch.commit();
    });
  }

  Future<int> deleteById(String id) {
    return (delete(drawingElementsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<int> deleteAll() {
    return delete(drawingElementsTable).go();
  }

  Future<void> reorder(List<String> orderedIds) {
    return transaction(() async {
      final batch = db.batch();
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(
          drawingElementsTable,
          DrawingElementsTableCompanion(zIndex: Value(i)),
          where: (t) => t.id.equals(orderedIds[i]),
        );
      }
      await batch.commit();
    });
  }
}
