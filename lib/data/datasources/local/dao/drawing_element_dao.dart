import 'package:drift/drift.dart';

import '../../../../domain/entities/drawing_account_summary.dart';
import '../database/app_database.dart';

class DrawingElementDao {
  DrawingElementDao(this.db);

  final AppDatabase db;

  int get activeAccountNumber => db.activeAccountNumber;

  Future<void> useAccount(int accountNumber) {
    return db.useAccount(accountNumber);
  }

  Future<List<DrawingAccountSummary>> loadAccountSummaries() {
    return db.loadAccountSummaries();
  }

  Stream<List<DrawingElementsTableData>> watchAll() {
    return db.watchElements();
  }

  Future<List<DrawingElementsTableData>> loadAll() {
    return db.loadElements();
  }

  Future<DrawingElementsTableData?> findById(String id) {
    return db.elementById(id);
  }

  Future<List<DrawingElementsTableData>> loadInViewport({
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
  }) async {
    final elements = await db.loadElements();
    return elements.where((element) {
      if (element.type == 'rect' || element.type == 'line') {
        return true;
      }

      if (element.type != 'stroke') {
        return false;
      }

      final strokeMaxX = element.strokeMaxX;
      final strokeMinX = element.strokeMinX;
      final strokeMaxY = element.strokeMaxY;
      final strokeMinY = element.strokeMinY;

      if (strokeMaxX == null ||
          strokeMinX == null ||
          strokeMaxY == null ||
          strokeMinY == null) {
        return false;
      }

      return strokeMaxX >= minX &&
          strokeMinX <= maxX &&
          strokeMaxY >= minY &&
          strokeMinY <= maxY;
    }).toList(growable: false);
  }

  Future<void> insertElement(DrawingElementsTableCompanion companion) async {
    final element = companion.toData();
    if (await db.containsElement(element.id)) {
      throw StateError(
        'Drawing element with id "${element.id}" already exists',
      );
    }
    await db.insertElement(element);
  }

  Future<void> upsertElement(DrawingElementsTableCompanion companion) {
    return db.upsertElement(companion.toData());
  }

  Future<bool> updateElement(DrawingElementsTableCompanion companion) {
    final id = companion.id.present ? companion.id.value : null;
    if (id == null) {
      return Future.value(false);
    }
    return db.updateElement(companion.toData());
  }

  Future<void> updateAll(List<DrawingElementsTableCompanion> companions) async {
    for (final companion in companions) {
      final id = companion.id.present ? companion.id.value : null;
      if (id != null) {
        await db.patchElement(id, companion);
      }
    }
  }

  Future<int> deleteById(String id) {
    return db.deleteElement(id);
  }

  Future<int> deleteAll() {
    return db.clearElements();
  }

  Future<void> reorder(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await db.patchElement(
        orderedIds[i],
        DrawingElementsTableCompanion(zIndex: Value(i)),
      );
    }
  }
}
