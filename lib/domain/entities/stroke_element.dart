import 'package:flutter/material.dart';
import 'drawing_element.dart';
import 'color_serialization.dart';

// ---------------------------------------------------------------------------
// StrokeElement — Represents a freehand pen/pencil stroke.
//
// RELATIVE POINTS OPTIMISATION
// ─────────────────────────────
// [relativePoints] are offsets FROM [position], not absolute canvas coords.
//
//   Absolute canvas point = position + relativePoints[i]
//
// WHY THIS MATTERS:
//   A typical stroke may have 500–2000 sampled Offset values.
//   Without this pattern, dragging the element would require iterating every
//   point and recalculating its world coordinate → O(n) writes per frame.
//   With it, a drag is a SINGLE field update (position) → O(1).
//
//   The [absolutePoints] getter materialises world coordinates lazily, only
//   when the Painter actually needs to draw them.
//
// DURING LIVE DRAWING (before the stroke is "committed"):
//   The active tool accumulates raw Offsets as the user draws.
//   On finalisation, the first raw point becomes [position], and every
//   other point is offset-subtracted → stored as [relativePoints].
// ---------------------------------------------------------------------------
@immutable
class StrokeElement extends DrawingElement {
  /// Geometry stored relative to [position].
  /// EMPTY list = degenerate stroke (single tap, rendered as a dot).
  final List<Offset> relativePoints;

  /// Whether the stroke path is closed (last point connects to first).
  final bool isClosed;

  const StrokeElement({
    required super.id,
    required super.color,
    required super.strokeWidth,
    required super.position,
    super.zIndex,
    required this.relativePoints,
    this.isClosed = false,
  });

  @override
  ElementType get type => ElementType.stroke;

  // ---- Computed absolute geometry ----------------------------------------

  /// Materialise world-space points for the CustomPainter.
  /// This is intentionally a getter (not cached) — the Painter calls it once
  /// per paint cycle, and caching would require invalidation logic.
  List<Offset> get absolutePoints =>
      relativePoints.map((p) => position + p).toList(growable: false);

  // ---- Bounding box -------------------------------------------------------

  @override
  Rect get worldBounds {
    if (relativePoints.isEmpty) {
      // Degenerate stroke: single point, give it a minimum tap target.
      return Rect.fromCircle(center: position, radius: strokeWidth / 2);
    }
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in relativePoints) {
      final ax = position.dx + p.dx;
      final ay = position.dy + p.dy;
      if (ax < minX) minX = ax;
      if (ay < minY) minY = ay;
      if (ax > maxX) maxX = ax;
      if (ay > maxY) maxY = ay;
    }
    // Expand by half stroke-width so hit-testing is pixel-accurate.
    final half = strokeWidth / 2;
    return Rect.fromLTRB(minX - half, minY - half, maxX + half, maxY + half);
  }

  // ---- Factory helpers ----------------------------------------------------

  /// Convenience constructor: accepts raw (absolute) points recorded during
  /// drawing, normalises them into the relative representation automatically.
  ///
  /// Usage in the tool layer:
  ///   final stroke = StrokeElement.fromAbsolutePoints(
  ///     id: uuid.v4(), rawPoints: buffer, color: ..., strokeWidth: ...);
  factory StrokeElement.fromAbsolutePoints({
    required String id,
    required List<Offset> rawPoints,
    required Color color,
    required double strokeWidth,
    int zIndex = 0,
    bool isClosed = false,
  }) {
    assert(rawPoints.isNotEmpty, 'rawPoints must not be empty');
    final anchor = rawPoints.first;
    final relative = rawPoints.map((p) => p - anchor).toList(growable: false);
    return StrokeElement(
      id: id,
      color: color,
      strokeWidth: strokeWidth,
      position: anchor,
      zIndex: zIndex,
      relativePoints: relative,
      isClosed: isClosed,
    );
  }

  // ---- CopyWith -----------------------------------------------------------

  @override
  StrokeElement copyWith({
    String? id,
    Color? color,
    double? strokeWidth,
    Offset? position,
    int? zIndex,
    List<Offset>? relativePoints,
    bool? isClosed,
  }) {
    return StrokeElement(
      id: id ?? this.id,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      position: position ?? this.position,
      zIndex: zIndex ?? this.zIndex,
      relativePoints: relativePoints ?? this.relativePoints,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  // ---- Serialisation ------------------------------------------------------

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'stroke',
    'color': colorToJson(color),
    'strokeWidth': strokeWidth,
    'positionX': position.dx,
    'positionY': position.dy,
    'zIndex': zIndex,
    'isClosed': isClosed,
    'relativePoints': relativePoints
        .map((p) => {'x': p.dx, 'y': p.dy})
        .toList(growable: false),
  };

  factory StrokeElement.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['relativePoints'] as List<dynamic>)
        .map(
          (p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()),
        )
        .toList(growable: false);

    return StrokeElement(
      id: json['id'] as String,
      color: colorFromJson(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      zIndex: (json['zIndex'] as int?) ?? 0,
      isClosed: (json['isClosed'] as bool?) ?? false,
      relativePoints: rawPoints,
    );
  }
}
