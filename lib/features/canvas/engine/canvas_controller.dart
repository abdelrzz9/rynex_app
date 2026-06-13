import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/canvas_constants.dart';

class CanvasController {
  final TransformationController _transformationController;

  CanvasController() : _transformationController = TransformationController();

  TransformationController get transformationController => _transformationController;

  Matrix4 get transformMatrix => _transformationController.value;

  set transformMatrix(Matrix4 value) => _transformationController.value = value;

  double get zoom {
    final values = _transformationController.value.storage;
    return values[0];
  }

  set zoom(double value) {
    final clamped = value.clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    final matrix = _transformationController.value;
    matrix[0] = clamped;
    matrix[5] = clamped;
    _transformationController.value = matrix;
  }

  Offset get pan {
    final values = _transformationController.value.storage;
    return Offset(values[12], values[13]);
  }

  set pan(Offset value) {
    final matrix = _transformationController.value;
    matrix[12] = value.dx;
    matrix[13] = value.dy;
    _transformationController.value = matrix;
  }

  Offset screenToWorld(Offset screenPoint) {
    final matrix = Matrix4.inverted(_transformationController.value);
    final transformed = MatrixUtils.transformPoint(matrix, screenPoint);
    return transformed;
  }

  Offset worldToScreen(Offset worldPoint) {
    return MatrixUtils.transformPoint(_transformationController.value, worldPoint);
  }

  Rect screenToWorldRect(Rect screenRect) {
    final topLeft = screenToWorld(screenRect.topLeft);
    final bottomRight = screenToWorld(screenRect.bottomRight);
    return Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);
  }

  Rect worldToScreenRect(Rect worldRect) {
    final topLeft = worldToScreen(worldRect.topLeft);
    final bottomRight = worldToScreen(worldRect.bottomRight);
    return Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);
  }

  Rect getVisibleWorldRect(Size screenSize) {
    return screenToWorldRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height));
  }

  void zoomToPoint(Offset screenPoint, double delta) {
    final worldPoint = screenToWorld(screenPoint);
    final currentZoom = zoom;
    final newZoom = (currentZoom * (1 + delta)).clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    final matrix = _transformationController.value;
    matrix[0] = newZoom;
    matrix[5] = newZoom;
    matrix[12] = screenPoint.dx - worldPoint.dx * newZoom;
    matrix[13] = screenPoint.dy - worldPoint.dy * newZoom;
    _transformationController.value = matrix;
  }

  void panBy(Offset delta) {
    final matrix = _transformationController.value;
    matrix[12] += delta.dx;
    matrix[13] += delta.dy;
    _transformationController.value = matrix;
  }

  void reset() {
    _transformationController.value = Matrix4.identity();
  }

  void zoomToFit(Size screenSize, Rect contentBounds) {
    if (contentBounds.isEmpty) return;
    final scaleX = screenSize.width / contentBounds.width;
    final scaleY = screenSize.height / contentBounds.height;
    final scale = math.min(scaleX, scaleY) * 0.9;
    final zoom = scale.clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    final center = contentBounds.center;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    final matrix = Matrix4.identity();
    matrix[0] = zoom;
    matrix[5] = zoom;
    matrix[12] = screenCenter.dx - center.dx * zoom;
    matrix[13] = screenCenter.dy - center.dy * zoom;
    _transformationController.value = matrix;
  }

  void dispose() {
    _transformationController.dispose();
  }
}
