import 'package:flutter/material.dart';
import 'shape_entity.dart';
import 'shape_type.dart';
import 'shape.dart';

class RectangleShape extends ShapeEntity {
  final double cornerRadius;

  RectangleShape({
    required super.id,
    required super.boundingBox,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
    this.cornerRadius = 0.0,
  }) : super(type: ShapeType.rectangle);

  @override
  bool hitTest(Offset point) {
    final local = ShapeEntity.rotatePoint(point, center, -rotation);
    return Rect.fromLTWH(
      boundingBox.left + cornerRadius,
      boundingBox.top,
      boundingBox.width - 2 * cornerRadius,
      boundingBox.height,
    ).contains(local) ||
        Rect.fromLTWH(
          boundingBox.left,
          boundingBox.top + cornerRadius,
          boundingBox.width,
          boundingBox.height - 2 * cornerRadius,
        ).contains(local);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'rectangle',
        'x': boundingBox.left,
        'y': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
        'rotation': rotation,
        'cornerRadius': cornerRadius,
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
  RectangleShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    double? cornerRadius,
  }) {
    return RectangleShape(
      id: id,
      boundingBox: boundingBox ?? this.boundingBox,
      rotation: rotation ?? this.rotation,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  List<Object?> get props => [...super.props, cornerRadius];
}

class RoundedRectShape extends RectangleShape {
  final double topLeftRadius;
  final double topRightRadius;
  final double bottomRightRadius;
  final double bottomLeftRadius;

  RoundedRectShape({
    required super.id,
    required super.boundingBox,
    super.rotation,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
    this.topLeftRadius = 0.0,
    this.topRightRadius = 0.0,
    this.bottomRightRadius = 0.0,
    this.bottomLeftRadius = 0.0,
  }) : super(cornerRadius: 0.0);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'type': 'roundedRect',
        'topLeftRadius': topLeftRadius,
        'topRightRadius': topRightRadius,
        'bottomRightRadius': bottomRightRadius,
        'bottomLeftRadius': bottomLeftRadius,
      };

  @override
  RoundedRectShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    double? cornerRadius,
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomRightRadius,
    double? bottomLeftRadius,
  }) {
    return RoundedRectShape(
      id: id,
      boundingBox: boundingBox ?? this.boundingBox,
      rotation: rotation ?? this.rotation,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
      topLeftRadius: topLeftRadius ?? this.topLeftRadius,
      topRightRadius: topRightRadius ?? this.topRightRadius,
      bottomRightRadius: bottomRightRadius ?? this.bottomRightRadius,
      bottomLeftRadius: bottomLeftRadius ?? this.bottomLeftRadius,
    );
  }

  @override
  List<Object?> get props => [...super.props, topLeftRadius, topRightRadius, bottomRightRadius, bottomLeftRadius];
}
