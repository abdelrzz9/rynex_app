import 'dart:math';
import 'package:flutter/material.dart';
import 'shape.dart';
import 'shape_entity.dart';
import 'shape_type.dart';

class PolygonShape extends ShapeEntity {
  final int sides;

  PolygonShape({
    required super.id,
    required super.boundingBox,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
    this.sides = 6,
  }) : super(type: ShapeType.polygon);

  List<Offset> get vertices {
    final center = boundingBox.center;
    final radius = min(boundingBox.width, boundingBox.height) / 2;
    final vertices = <Offset>[];
    final angleStep = 2 * pi / sides;
    for (var i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * angleStep;
      vertices.add(Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ));
    }
    return vertices;
  }

  double _sign(Offset p1, Offset p2, Offset p3) {
    return (p1.dx - p3.dx) * (p2.dy - p3.dy) -
        (p2.dx - p3.dx) * (p1.dy - p3.dy);
  }

  @override
  bool hitTest(Offset point) {
    final local = ShapeEntity.rotatePoint(point, center, -rotation);
    final verts = vertices;
    final n = verts.length;
    bool positive = false, negative = false;
    for (var i = 0; i < n; i++) {
      final d = _sign(local, verts[i], verts[(i + 1) % n]);
      if (d > 0) positive = true;
      if (d < 0) negative = true;
      if (positive && negative) return false;
    }
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'polygon',
        'x': boundingBox.left,
        'y': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
        'rotation': rotation,
        'sides': sides,
        'strokeColor': style.strokeColor.toARGB32(),
        'strokeWidth': style.strokeWidth,
        'strokeStyle': style.strokeStyle.name,
        'fillColor': style.fillColor.toARGB32(),
        'fillStyle': style.fillStyle.name,
        'roughness': style.roughness.name,
        'opacity': style.opacity,
        'layerOrder': layer.order,
        'isLocked': isLocked,
        'isVisible': isVisible,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  PolygonShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    int? sides,
  }) {
    return PolygonShape(
      id: id,
      boundingBox: boundingBox ?? this.boundingBox,
      rotation: rotation ?? this.rotation,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
      sides: sides ?? this.sides,
    );
  }

  @override
  List<Object?> get props => [...super.props, sides];
}
