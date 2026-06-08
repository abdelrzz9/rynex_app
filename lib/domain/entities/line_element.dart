import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'drawing_element.dart';
import 'color_serialization.dart';

// ---------------------------------------------------------------------------
// LineElement — A straight line between two points.
//
// RELATIVE TRANSFORM CONVENTION:
//   [position]     = world-space anchor (identical to the line's start point).
//   [relativeEnd]  = the end point expressed AS AN OFFSET FROM [position].
//
//   Absolute start = position                      (zero offset)
//   Absolute end   = position + relativeEnd
//
//   Moving: update [position] → O(1). The relativeEnd does not change, so
//   the length and angle of the line are fully preserved automatically.
//
// This design is consistent with StrokeElement's relative-points pattern —
// all geometry in every element type is relative to its anchor.
//
// ARROWHEADS (optional):
//   [startArrow] / [endArrow] flags tell the Painter to draw arrowhead
//   decorations. The geometry for the arrowheads is computed in the Painter
//   from the line direction, keeping the entity itself pure data.
// ---------------------------------------------------------------------------
@immutable
class LineElement extends DrawingElement {
  /// End point RELATIVE to [position] (the start point).
  /// Absolute end = position + relativeEnd.
  final Offset relativeEnd;

  /// Draw an arrowhead at the start of the line.
  final bool startArrow;

  /// Draw an arrowhead at the end of the line.
  final bool endArrow;

  const LineElement({
    required super.id,
    required super.color,
    required super.strokeWidth,
    required super.position,
    super.zIndex,
    required this.relativeEnd,
    this.startArrow = false,
    this.endArrow = false,
  });

  @override
  ElementType get type => ElementType.line;

  // ---- Computed absolute geometry ----------------------------------------

  /// Absolute world position of the start point (== [position]).
  Offset get absoluteStart => position;

  /// Absolute world position of the end point.
  Offset get absoluteEnd => position + relativeEnd;

  /// Line length in world pixels.
  double get length => relativeEnd.distance;

  /// Angle of the line in radians (atan2 of dy, dx).
  double get angle => math.atan2(relativeEnd.dy, relativeEnd.dx);

  /// Unit direction vector from start to end.
  Offset get direction {
    final len = length;
    if (len == 0) return Offset.zero;
    return relativeEnd / len;
  }

  @override
  Rect get worldBounds {
    final half = strokeWidth / 2 + 4; // +4 px padding for hit-testing comfort
    return Rect.fromPoints(absoluteStart, absoluteEnd).inflate(half);
  }

  // ---- CopyWith -----------------------------------------------------------

  @override
  LineElement copyWith({
    String? id,
    Color? color,
    double? strokeWidth,
    Offset? position,
    int? zIndex,
    Offset? relativeEnd,
    bool? startArrow,
    bool? endArrow,
  }) {
    return LineElement(
      id: id ?? this.id,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      position: position ?? this.position,
      zIndex: zIndex ?? this.zIndex,
      relativeEnd: relativeEnd ?? this.relativeEnd,
      startArrow: startArrow ?? this.startArrow,
      endArrow: endArrow ?? this.endArrow,
    );
  }

  // ---- Serialisation ------------------------------------------------------

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'line',
    'color': colorToJson(color),
    'strokeWidth': strokeWidth,
    'positionX': position.dx,
    'positionY': position.dy,
    'zIndex': zIndex,
    'relativeEndX': relativeEnd.dx,
    'relativeEndY': relativeEnd.dy,
    'startArrow': startArrow,
    'endArrow': endArrow,
  };

  factory LineElement.fromJson(Map<String, dynamic> json) {
    return LineElement(
      id: json['id'] as String,
      color: colorFromJson(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      zIndex: (json['zIndex'] as int?) ?? 0,
      relativeEnd: Offset(
        (json['relativeEndX'] as num).toDouble(),
        (json['relativeEndY'] as num).toDouble(),
      ),
      startArrow: (json['startArrow'] as bool?) ?? false,
      endArrow: (json['endArrow'] as bool?) ?? false,
    );
  }
}
