import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Discriminator enum — used by DB layer as the type column.
// ---------------------------------------------------------------------------
enum ElementType { stroke, rect, line }

// ---------------------------------------------------------------------------
// DrawingElement — Abstract base for all shapes in the Scene Graph.
//
// DESIGN DECISION — "position as world-space anchor":
//   Every element stores a [position] in world (canvas) coordinates.
//   All geometric data in subclasses (points, width/height, endpoints) is
//   stored RELATIVE to this anchor. This gives us a critical performance win:
//
//     Moving an element = update ONE Offset (position).
//                         No geometry recalculation needed.
//
//   Rendering reads: absoluteCoordinate = position + relativeCoordinate.
//   This indirection is nearly free at paint time (single Offset addition per
//   point) but saves O(n) writes on every drag event for StrokeElements.
// ---------------------------------------------------------------------------
@immutable
abstract class DrawingElement {
  final String id;

  /// Stroke/fill color.
  final Color color;

  /// Stroke width in logical pixels.
  final double strokeWidth;

  /// World-space anchor point.
  ///   • StrokeElement : first recorded touch point of the stroke.
  ///   • RectElement   : top-left corner of the bounding box.
  ///   • LineElement   : line start point (start == position for consistency).
  final Offset position;

  /// Painter z-order. Higher values appear on top.
  final int zIndex;

  const DrawingElement({
    required this.id,
    required this.color,
    required this.strokeWidth,
    required this.position,
    this.zIndex = 0,
  });

  // ---- Subclass contract --------------------------------------------------

  ElementType get type;

  /// Produce a bounding [Rect] in world coordinates.
  /// Used for hit-testing and selection handles.
  Rect get worldBounds;

  /// Serialise to a plain JSON map (stored in DB as a TEXT column blob).
  /// The [type] key MUST be present so the deserialiser can reconstruct the
  /// correct subclass.
  Map<String, dynamic> toJson();

  /// Immutable update — returns a new instance with the overridden fields.
  /// Each subclass overrides this to include its own fields.
  DrawingElement copyWith({
    String? id,
    Color? color,
    double? strokeWidth,
    Offset? position,
    int? zIndex,
  });

  // ---- Equality -----------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrawingElement &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      '${type.name}($id pos=${position.dx.toStringAsFixed(1)},${position.dy.toStringAsFixed(1)})';
}
