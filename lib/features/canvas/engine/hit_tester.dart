import 'package:flutter/material.dart';
import '../../shapes/domain/entities/shape_entity.dart';
import '../domain/entities/canvas_transform.dart';

abstract class HitTester {
  ShapeEntity? hitTest(List<ShapeEntity> shapes, Offset point);
  List<ShapeEntity> hitTestRect(List<ShapeEntity> shapes, Rect rect);
}

class DefaultHitTester implements HitTester {
  @override
  ShapeEntity? hitTest(List<ShapeEntity> shapes, Offset point) {
    for (final shape in shapes.reversed) {
      if (!shape.isVisible || shape.isLocked) continue;
      if (shape.hitTest(point)) return shape;
    }
    return null;
  }

  @override
  List<ShapeEntity> hitTestRect(List<ShapeEntity> shapes, Rect rect) {
    return shapes.where((s) {
      if (!s.isVisible || s.isLocked) return false;
      return rect.overlaps(s.rotatedBoundingBox);
    }).toList();
  }

  ShapeEntity? hitTestTopmost(List<ShapeEntity> shapes, Offset point, CanvasTransform transform) {
    final worldPoint = transform.screenToWorld(point);
    return hitTest(shapes, worldPoint);
  }

  List<ShapeEntity> hitTestScreenRect(List<ShapeEntity> shapes, Rect screenRect, CanvasTransform transform) {
    final worldRect = transform.screenToWorldRect(screenRect);
    return hitTestRect(shapes, worldRect);
  }
}
