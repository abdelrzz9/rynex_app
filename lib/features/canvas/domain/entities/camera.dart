import 'package:flutter/material.dart';
import '../../../../core/constants/canvas_constants.dart';

@immutable
class Camera {
  final double zoom;
  final Offset pan;

  const Camera({
    this.zoom = CanvasConstants.defaultZoom,
    this.pan = Offset.zero,
  });

  Offset screenToWorld(Offset screenPoint) {
    return (screenPoint - pan) / zoom;
  }

  Offset worldToScreen(Offset worldPoint) {
    return worldPoint * zoom + pan;
  }

  Rect screenToWorldRect(Rect screenRect) {
    return Rect.fromLTRB(
      (screenRect.left - pan.dx) / zoom,
      (screenRect.top - pan.dy) / zoom,
      (screenRect.right - pan.dx) / zoom,
      (screenRect.bottom - pan.dy) / zoom,
    );
  }

  Rect worldToScreenRect(Rect worldRect) {
    return Rect.fromLTRB(
      worldRect.left * zoom + pan.dx,
      worldRect.top * zoom + pan.dy,
      worldRect.right * zoom + pan.dx,
      worldRect.bottom * zoom + pan.dy,
    );
  }

  Rect getVisibleWorldRect(Size screenSize) {
    return screenToWorldRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height));
  }

  Camera zoomToPoint(Offset screenPoint, double factor) {
    final newZoom = (zoom * factor).clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    final worldPoint = screenToWorld(screenPoint);
    final newPan = screenPoint - worldPoint * newZoom;
    return Camera(zoom: newZoom, pan: newPan);
  }

  Camera panBy(Offset delta) {
    return Camera(zoom: zoom, pan: pan + delta);
  }

  Camera copyWith({double? zoom, Offset? pan}) {
    return Camera(
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
    );
  }

  Matrix4 toMatrix4() {
    return Matrix4.identity()
      ..[0] = zoom
      ..[5] = zoom
      ..[12] = pan.dx
      ..[13] = pan.dy;
  }

  static Camera fromMatrix4(Matrix4 matrix) {
    final storage = matrix.storage;
    final z = storage[0];
    final px = storage[12];
    final py = storage[13];
    return Camera(zoom: z, pan: Offset(px, py));
  }

  static Camera lerp(Camera a, Camera b, double t) {
    return Camera(
      zoom: a.zoom + (b.zoom - a.zoom) * t,
      pan: Offset.lerp(a.pan, b.pan, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Camera &&
          zoom == other.zoom &&
          pan == other.pan;

  @override
  int get hashCode => Object.hash(zoom, pan);

  @override
  String toString() => 'Camera(zoom: $zoom, pan: $pan)';
}
