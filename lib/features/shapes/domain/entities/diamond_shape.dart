import 'package:flutter/material.dart';
import 'shape.dart';
import 'shape_entity.dart';
import 'shape_type.dart';

class DiamondShape extends ShapeEntity {
  DiamondShape({
    required super.id,
    required super.boundingBox,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
  }) : super(type: ShapeType.diamond);

  @override
  bool hitTest(Offset point) {
    final local = ShapeEntity.rotatePoint(point, center, -rotation);
    final cx = boundingBox.center.dx;
    final cy = boundingBox.center.dy;
    final hw = boundingBox.width / 2;
    final hh = boundingBox.height / 2;
    if (hw <= 0 || hh <= 0) return false;
    final dx = (local.dx - cx).abs() / hw;
    final dy = (local.dy - cy).abs() / hh;
    return dx + dy <= 1.0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'diamond',
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
  DiamondShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
  }) {
    return DiamondShape(
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
