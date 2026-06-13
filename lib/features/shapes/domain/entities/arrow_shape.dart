import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/utils/geometry_utils.dart';
import 'shape_entity.dart';
import 'shape_type.dart';
import 'shape.dart';

enum ArrowheadStyle { triangle, circle, diamond, none }

class ArrowShape extends ShapeEntity {
  final Offset startPoint;
  final Offset endPoint;
  final ArrowheadStyle startArrowhead;
  final ArrowheadStyle endArrowhead;

  ArrowShape({
    required super.id,
    required this.startPoint,
    required this.endPoint,
    this.startArrowhead = ArrowheadStyle.none,
    this.endArrowhead = ArrowheadStyle.triangle,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
  }) : super(
          type: ShapeType.arrow,
          boundingBox: Rect.fromPoints(startPoint, endPoint),
          rotation: 0.0,
        );

  double get length => (endPoint - startPoint).distance;
  double get angle => atan2(endPoint.dy - startPoint.dy, endPoint.dx - startPoint.dx);

  @override
  bool hitTest(Offset point) {
    return perpendicularDistance(point, startPoint, endPoint) <= 5.0;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'arrow',
        'startX': startPoint.dx,
        'startY': startPoint.dy,
        'endX': endPoint.dx,
        'endY': endPoint.dy,
        'startArrowhead': startArrowhead.name,
        'endArrowhead': endArrowhead.name,
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
  ArrowShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    Offset? startPoint,
    Offset? endPoint,
    ArrowheadStyle? startArrowhead,
    ArrowheadStyle? endArrowhead,
  }) {
    return ArrowShape(
      id: id,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      startArrowhead: startArrowhead ?? this.startArrowhead,
      endArrowhead: endArrowhead ?? this.endArrowhead,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [...super.props, startPoint, endPoint, startArrowhead, endArrowhead];
}
