import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/utils/geometry_utils.dart';
import 'shape.dart';
import 'shape_entity.dart';
import 'shape_type.dart';

class FreehandShape extends ShapeEntity {
  final List<Offset> points;
  final bool isClosed;

  FreehandShape({
    required super.id,
    required this.points,
    this.isClosed = false,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
  }) : super(
          type: ShapeType.freehand,
          boundingBox: _computeBounds(points),
          rotation: 0.0,
        );

  static Rect _computeBounds(List<Offset> pts) {
    if (pts.isEmpty) return Rect.zero;
    var minX = pts[0].dx;
    var minY = pts[0].dy;
    var maxX = minX;
    var maxY = minY;
    for (final p in pts) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
      maxX = max(maxX, p.dx);
      maxY = max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool hitTest(Offset point) {
    if (points.isEmpty) return false;
    final threshold = max(5.0, style.strokeWidth / 2);
    for (var i = 0; i < points.length - 1; i++) {
      if (perpendicularDistance(point, points[i], points[i + 1]) <= threshold) {
        return true;
      }
    }
    return false;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'freehand',
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'isClosed': isClosed,
        'strokeColor': style.strokeColor.toARGB32(),
        'strokeWidth': style.strokeWidth,
        'strokeStyle': style.strokeStyle.name,
        'roughness': style.roughness.name,
        'opacity': style.opacity,
        'layerOrder': layer.order,
        'isLocked': isLocked,
        'isVisible': isVisible,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  FreehandShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    List<Offset>? points,
    bool? isClosed,
  }) {
    return FreehandShape(
      id: id,
      points: points ?? this.points,
      isClosed: isClosed ?? this.isClosed,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [...super.props, points, isClosed];
}
