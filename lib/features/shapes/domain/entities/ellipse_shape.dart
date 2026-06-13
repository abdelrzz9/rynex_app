import 'package:flutter/material.dart';
import 'shape_entity.dart';
import 'shape_type.dart';
import 'shape.dart';

class EllipseShape extends ShapeEntity {
  EllipseShape({
    required super.id,
    required super.boundingBox,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
  }) : super(type: ShapeType.ellipse);

  @override
  bool hitTest(Offset point) {
    final local = ShapeEntity.rotatePoint(point, center, -rotation);
    final rx = boundingBox.width / 2;
    final ry = boundingBox.height / 2;
    if (rx <= 0 || ry <= 0) return false;
    final dx = (local.dx - boundingBox.center.dx) / rx;
    final dy = (local.dy - boundingBox.center.dy) / ry;
    return dx * dx + dy * dy <= 1.0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'ellipse',
        'x': boundingBox.left,
        'y': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
        'rotation': rotation,
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
  EllipseShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
  }) {
    return EllipseShape(
      id: id,
      boundingBox: boundingBox ?? this.boundingBox,
      rotation: rotation ?? this.rotation,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }
}
