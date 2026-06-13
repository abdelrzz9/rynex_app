import 'dart:math';
import 'package:flutter/material.dart';

double distanceBetween(Offset a, Offset b) {
  return (a - b).distance;
}

double clampDouble(double value, double min, double max) {
  return value.clamp(min, max);
}

double radiansToDegrees(double radians) {
  return radians * 180 / pi;
}

double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

Offset rotatePoint(Offset point, Offset center, double angle) {
  final translated = point - center;
  final cosA = cos(angle);
  final sinA = sin(angle);
  return Offset(
    translated.dx * cosA - translated.dy * sinA + center.dx,
    translated.dx * sinA + translated.dy * cosA + center.dy,
  );
}

Offset rotatePointAroundOrigin(Offset point, double angle) {
  final cosA = cos(angle);
  final sinA = sin(angle);
  return Offset(
    point.dx * cosA - point.dy * sinA,
    point.dx * sinA + point.dy * cosA,
  );
}

Rect rotateRect(Rect rect, double angle) {
  if (angle == 0) return rect;
  final center = rect.center;
  final corners = [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
  final rotated = corners.map((c) => rotatePoint(c, center, angle));
  final minX = rotated.map((p) => p.dx).reduce(min);
  final minY = rotated.map((p) => p.dy).reduce(min);
  final maxX = rotated.map((p) => p.dx).reduce(max);
  final maxY = rotated.map((p) => p.dy).reduce(max);
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

double normalizeAngle(double angle) {
  angle = angle % (2 * pi);
  if (angle < 0) angle += 2 * pi;
  return angle;
}

double angleBetween(Offset from, Offset to) {
  return atan2(to.dy - from.dy, to.dx - from.dx);
}

Rect expandRectToContain(Rect rect, Offset point) {
  return Rect.fromLTRB(
    min(rect.left, point.dx),
    min(rect.top, point.dy),
    max(rect.right, point.dx),
    max(rect.bottom, point.dy),
  );
}

Offset lerpOffset(Offset a, Offset b, double t) {
  return Offset(lerpDouble(a.dx, b.dx, t), lerpDouble(a.dy, b.dy, t));
}
