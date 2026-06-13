import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'canvas_transform.dart';

class Viewport extends Equatable {
  final Rect visibleRect;
  final double zoom;
  final Offset pan;

  const Viewport({
    required this.visibleRect,
    required this.zoom,
    required this.pan,
  });

  factory Viewport.fromTransform(CanvasTransform transform, Size screenSize) {
    return Viewport(
      visibleRect: transform.getVisibleWorldRect(screenSize),
      zoom: transform.zoom,
      pan: transform.pan,
    );
  }

  bool isVisible(Rect worldRect) {
    return visibleRect.overlaps(worldRect);
  }

  @override
  List<Object?> get props => [visibleRect, zoom, pan];
}
