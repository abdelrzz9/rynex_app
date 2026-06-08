import 'dart:convert';
import 'package:drift/drift.dart';

import '../../domain/entities/drawing_element.dart';
import '../../domain/entities/color_serialization.dart';
import '../../domain/entities/stroke_element.dart';
import '../../domain/entities/rect_element.dart';
import '../../domain/entities/line_element.dart';
import '../../domain/entities/drawing_element_factory.dart';
import '../datasources/local/database/app_database.dart';

abstract final class DrawingElementMapper {
  const DrawingElementMapper._();

  /// Convert a DB Row (TableData) into a pure Domain Entity
  static DrawingElement toEntity(DrawingElementsTableData row) {
    final Map<String, dynamic> jsonMap = jsonDecode(row.geometryJson);
    return DrawingElementFactory.fromJson(jsonMap);
  }

  /// Convert a Domain Entity into a DB Companion for inserts/updates
  static DrawingElementsTableCompanion toCompanion(DrawingElement entity) {
    final jsonStr = jsonEncode(entity.toJson());

    // Base companion with shared fields
    var companion = DrawingElementsTableCompanion(
      id: Value(entity.id),
      type: Value(entity.type.name),
      color: Value(colorToJson(entity.color)),
      strokeWidth: Value(entity.strokeWidth),
      positionX: Value(entity.position.dx),
      positionY: Value(entity.position.dy),
      zIndex: Value(entity.zIndex),
      createdAt: Value(DateTime.now().toUtc()),
      geometryJson: Value(jsonStr),
    );

    // Inject type-specific fast-path columns for indexing/culling
    if (entity is RectElement) {
      companion = companion.copyWith(
        rectWidth: Value(entity.width),
        rectHeight: Value(entity.height),
      );
    } else if (entity is LineElement) {
      companion = companion.copyWith(
        lineEndX: Value(entity.relativeEnd.dx),
        lineEndY: Value(entity.relativeEnd.dy),
      );
    } else if (entity is StrokeElement) {
      final bounds = entity.worldBounds;
      companion = companion.copyWith(
        strokeMinX: Value(bounds.left),
        strokeMinY: Value(bounds.top),
        strokeMaxX: Value(bounds.right),
        strokeMaxY: Value(bounds.bottom),
      );
    }

    return companion;
  }
}
