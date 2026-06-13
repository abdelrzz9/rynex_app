import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/utils/geometry_utils.dart';
import 'shape_entity.dart';
import 'shape_type.dart';
import 'shape.dart';

class LineShape extends ShapeEntity {
  final Offset startPoint;
  final Offset endPoint;

  LineShape({
    required super.id,
    required this.startPoint,
    required this.endPoint,
    super.style,
    super.layer,
    super.isLocked,
    super.isVisible,
    super.createdAt,
  }) : super(
          type: ShapeType.line,
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
        'type': 'line',
        'startX': startPoint.dx,
        'startY': startPoint.dy,
        'endX': endPoint.dx,
        'endY': endPoint.dy,
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
  LineShape copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
    Offset? startPoint,
    Offset? endPoint,
  }) {
    return LineShape(
      id: id,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      style: style ?? this.style,
      layer: layer ?? this.layer,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [...super.props, startPoint, endPoint];
}
