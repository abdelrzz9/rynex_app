import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class CanvasTransform extends Equatable {
  final double zoom;
  final Offset pan;

  const CanvasTransform({
    this.zoom = 1.0,
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

  CanvasTransform copyWith({double? zoom, Offset? pan}) {
    return CanvasTransform(
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
    );
  }

  @override
  List<Object?> get props => [zoom, pan];
}
