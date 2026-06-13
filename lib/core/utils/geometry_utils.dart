import 'dart:math';
import 'package:flutter/material.dart';

Offset rotatePointGlobal(Offset point, Offset center, double angle) {
  final translated = point - center;
  final cosA = cos(angle);
  final sinA = sin(angle);
  return Offset(
    translated.dx * cosA - translated.dy * sinA + center.dx,
    translated.dx * sinA + translated.dy * cosA + center.dy,
  );
}

double perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
  final dx = lineEnd.dx - lineStart.dx;
  final dy = lineEnd.dy - lineStart.dy;
  final mag = sqrt(dx * dx + dy * dy);
  if (mag < 1e-10) return (point - lineStart).distance;
  final u = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / (mag * mag);
  final uClamped = u.clamp(0.0, 1.0);
  final closest = Offset(lineStart.dx + uClamped * dx, lineStart.dy + uClamped * dy);
  return (point - closest).distance;
}

double lineSegmentDistance(Offset point, Offset a, Offset b) {
  return perpendicularDistance(point, a, b);
}

bool pointNearLineSegment(Offset point, Offset a, Offset b, double threshold) {
  return perpendicularDistance(point, a, b) <= threshold;
}

bool pointInRect(Offset point, Rect rect, double rotation) {
  if (rotation == 0) return rect.contains(point);
  final local = rotatePointGlobal(point, rect.center, -rotation);
  return rect.contains(local);
}

bool pointInEllipse(Offset point, Rect bounds, double rotation) {
  final local = rotation == 0
      ? point
      : rotatePointGlobal(point, bounds.center, -rotation);
  final rx = bounds.width / 2;
  final ry = bounds.height / 2;
  if (rx <= 0 || ry <= 0) return false;
  final dx = (local.dx - bounds.center.dx) / rx;
  final dy = (local.dy - bounds.center.dy) / ry;
  return dx * dx + dy * dy <= 1.0;
}

bool pointInDiamond(Offset point, Rect bounds, double rotation) {
  final local = rotation == 0
      ? point
      : rotatePointGlobal(point, bounds.center, -rotation);
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;
  final hw = bounds.width / 2;
  final hh = bounds.height / 2;
  if (hw <= 0 || hh <= 0) return false;
  final dx = (local.dx - cx).abs() / hw;
  final dy = (local.dy - cy).abs() / hh;
  return dx + dy <= 1.0;
}

double sign(Offset p1, Offset p2, Offset p3) {
  return (p1.dx - p3.dx) * (p2.dy - p3.dy) -
      (p2.dx - p3.dx) * (p1.dy - p3.dy);
}

bool pointInTriangle(Offset point, Offset v1, Offset v2, Offset v3) {
  final d1 = sign(point, v1, v2);
  final d2 = sign(point, v2, v3);
  final d3 = sign(point, v3, v1);
  final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
  final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
  return !(hasNeg && hasPos);
}

List<Offset> simplifyPoints(List<Offset> points, double epsilon) {
  if (points.length <= 2) return points;

  var maxDistance = 0.0;
  var maxIndex = 0;
  final last = points.length - 1;

  for (var i = 1; i < last; i++) {
    final distance = perpendicularDistance(points[i], points[0], points[last]);
    if (distance > maxDistance) {
      maxDistance = distance;
      maxIndex = i;
    }
  }

  if (maxDistance > epsilon) {
    final left = simplifyPoints(points.sublist(0, maxIndex + 1), epsilon);
    final right = simplifyPoints(points.sublist(maxIndex), epsilon);
    return [...left.sublist(0, left.length - 1), ...right];
  }

  return [points[0], points[last]];
}

Rect computeBoundingBox(List<Offset> points) {
  if (points.isEmpty) return Rect.zero;
  var minX = points[0].dx;
  var minY = points[0].dy;
  var maxX = minX;
  var maxY = minY;
  for (final p in points) {
    minX = min(minX, p.dx);
    minY = min(minY, p.dy);
    maxX = max(maxX, p.dx);
    maxY = max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

List<Offset> getRectCorners(Rect rect) {
  return [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
}

List<Offset> getRotatedRectCorners(Rect rect, double rotation) {
  if (rotation == 0) return getRectCorners(rect);
  final center = rect.center;
  return getRectCorners(rect)
      .map((c) => rotatePointGlobal(c, center, rotation))
      .toList();
}
