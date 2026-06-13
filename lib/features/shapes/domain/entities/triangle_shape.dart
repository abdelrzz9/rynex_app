import 'package:flutter/material.dart';
import 'shape_entity.dart';
import 'shape_type.dart';
import 'shape.dart';

enum TriangleDirection { up, down, left, right }

class TriangleShape extends ShapeEntity {
  final TriangleDirection direction;

  TriangleShape({
    required super.id,
    required super.boundingBox,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
    this.direction = TriangleDirection.up,
  }) : super(type: ShapeType.triangle);

  List<Offset> get vertices {
    final center = boundingBox.center;

    switch (direction) {
      case TriangleDirection.up:
        return [
          Offset(center.dx, boundingBox.top),
          Offset(boundingBox.left, boundingBox.bottom),
          Offset(boundingBox.right, boundingBox.bottom),
        ];
      case TriangleDirection.down:
        return [
          Offset(center.dx, boundingBox.bottom),
          Offset(boundingBox.left, boundingBox.top),
          Offset(boundingBox.right, boundingBox.top),
        ];
      case TriangleDirection.left:
        return [
          Offset(boundingBox.left, center.dy),
          Offset(boundingBox.right, boundingBox.top),
          Offset(boundingBox.right, boundingBox.bottom),
        ];
      case TriangleDirection.right:
        return [
          Offset(boundingBox.right, center.dy),
          Offset(boundingBox.left, boundingBox.top),
          Offset(boundingBox.left, boundingBox.bottom),
        ];
    }
  }

  double _sign(Offset p1, Offset p2, Offset p3) {
    return (p1.dx - p3.dx) * (p2.dy - p3.dy) -
        (p2.dx - p3.dx) * (p1.dy - p3.dy);
  }

  @override
  bool hitTest(Offset point) {
    final local = ShapeEntity.rotatePoint(point, center, -rotation);
    final verts = vertices;
    final d1 = _sign(local, verts[0], verts[1]);
    final d2 = _sign(local, verts[1], verts[2]);
    final d3 = _sign(local, verts[2], verts[0]);
    final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
    return !(hasNeg && hasPos);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'triangle',
        'x': boundingBox.left,
        'y': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
        'rotation': rotation,
        'direction': direction.name,
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
  TriangleShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    TriangleDirection? direction,
  }) {
    return TriangleShape(
      id: id,
      boundingBox: boundingBox ?? this.boundingBox,
      rotation: rotation ?? this.rotation,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
      direction: direction ?? this.direction,
    );
  }

  @override
  List<Object?> get props => [...super.props, direction];
}
