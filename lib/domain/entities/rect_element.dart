import 'package:flutter/material.dart';
import 'drawing_element.dart';
import 'color_serialization.dart';

// ---------------------------------------------------------------------------
// RectElement — Axis-aligned rectangle shape.
//
// RELATIVE TRANSFORM CONVENTION:
//   [position]  = top-left corner of the rectangle in world space.
//   [width]     = extent along the X axis (always positive).
//   [height]    = extent along the Y axis (always positive).
//
//   Moving:  update [position]         → O(1)
//   Scaling: update [width] / [height] → O(1)
//   No geometry list to iterate — extremely cheap.
//
// FILL vs STROKE:
//   [fillColor] is nullable. When null, the shape is drawn as stroke-only.
//   When non-null, the interior is filled before the stroke is painted.
// ---------------------------------------------------------------------------
@immutable
class RectElement extends DrawingElement {
  /// Width of the rectangle in logical pixels. Must be > 0.
  final double width;

  /// Height of the rectangle in logical pixels. Must be > 0.
  final double height;

  /// Optional fill color. Null = no fill (outline-only mode).
  final Color? fillColor;

  /// Corner radius for rounded rectangles. 0 = sharp corners.
  final double cornerRadius;

  const RectElement({
    required super.id,
    required super.color,
    required super.strokeWidth,
    required super.position,
    super.zIndex,
    required this.width,
    required this.height,
    this.fillColor,
    this.cornerRadius = 0,
  }) : assert(width > 0, 'RectElement.width must be positive'),
       assert(height > 0, 'RectElement.height must be positive'),
       assert(cornerRadius >= 0, 'cornerRadius must be non-negative');

  @override
  ElementType get type => ElementType.rect;

  // ---- Computed geometry --------------------------------------------------

  /// The world-space [Rect] of this element.
  /// This is the canonical bounding box — used for both rendering and
  /// hit-testing without any additional computation.
  Rect get worldRect => Rect.fromLTWH(position.dx, position.dy, width, height);

  /// Convenience: centre point in world space.
  Offset get worldCenter =>
      Offset(position.dx + width / 2, position.dy + height / 2);

  @override
  Rect get worldBounds {
    final half = strokeWidth / 2;
    return worldRect.inflate(half);
  }

  // ---- CopyWith -----------------------------------------------------------

  @override
  RectElement copyWith({
    String? id,
    Color? color,
    double? strokeWidth,
    Offset? position,
    int? zIndex,
    double? width,
    double? height,
    Color? fillColor,
    double? cornerRadius,
    // Pass [clearFillColor: true] to explicitly set fillColor to null.
    bool clearFillColor = false,
  }) {
    return RectElement(
      id: id ?? this.id,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      position: position ?? this.position,
      zIndex: zIndex ?? this.zIndex,
      width: width ?? this.width,
      height: height ?? this.height,
      fillColor: clearFillColor ? null : (fillColor ?? this.fillColor),
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  // ---- Serialisation ------------------------------------------------------

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'rect',
    'color': colorToJson(color),
    'strokeWidth': strokeWidth,
    'positionX': position.dx,
    'positionY': position.dy,
    'zIndex': zIndex,
    'width': width,
    'height': height,
    'fillColor': fillColor == null ? null : colorToJson(fillColor!),
    'cornerRadius': cornerRadius,
  };

  factory RectElement.fromJson(Map<String, dynamic> json) {
    return RectElement(
      id: json['id'] as String,
      color: colorFromJson(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      zIndex: (json['zIndex'] as int?) ?? 0,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      fillColor: json['fillColor'] != null
          ? colorFromJson(json['fillColor'] as int)
          : null,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0,
    );
  }
}
