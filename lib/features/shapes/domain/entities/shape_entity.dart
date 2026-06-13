import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'shape.dart';
import 'shape_type.dart';

abstract class ShapeEntity extends Equatable {
  final String id;
  final ShapeType type;
  final Rect boundingBox;
  final double rotation;
  final ShapeStyle style;
  final LayerInfo layer;
  final bool isLocked;
  final bool isVisible;
  final DateTime createdAt;

  ShapeEntity({
    required this.id,
    required this.type,
    required this.boundingBox,
    this.rotation = 0.0,
    this.style = const ShapeStyle(),
    this.layer = const LayerInfo(),
    this.isLocked = false,
    this.isVisible = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Offset get center => boundingBox.center;
  double get width => boundingBox.width;
  double get height => boundingBox.height;

  Rect get rotatedBoundingBox {
    if (rotation == 0) return boundingBox;
    final corners = [
      boundingBox.topLeft,
      boundingBox.topRight,
      boundingBox.bottomRight,
      boundingBox.bottomLeft,
    ];
    final rotated = corners.map((c) => rotatePoint(c, center, rotation));
    final minX = rotated.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final minY = rotated.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final maxX = rotated.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final maxY = rotated.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool hitTest(Offset point) {
    final local = rotatePoint(point, center, -rotation);
    return boundingBox.contains(local);
  }

  static Offset rotatePoint(Offset point, Offset center, double angle) {
    final translated = point - center;
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      translated.dx * cosA - translated.dy * sinA + center.dx,
      translated.dx * sinA + translated.dy * cosA + center.dy,
    );
  }

  Map<String, dynamic> toJson();
  ShapeEntity copyWith({
    Rect? boundingBox,
    double? rotation,
    ShapeStyle? style,
    LayerInfo? layer,
    bool? isLocked,
    bool? isVisible,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        boundingBox,
        rotation,
        style,
        layer,
        isLocked,
        isVisible,
        createdAt,
      ];
}
