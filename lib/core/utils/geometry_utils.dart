import 'dart:math';
import 'package:flutter/material.dart';

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
