import 'package:flutter/material.dart';

class DirtyRegionTracker {
  Rect? _accumulatedBounds;

  void addRect(Rect rect) {
    _accumulatedBounds = _accumulatedBounds != null
        ? _accumulatedBounds!.expandToInclude(rect.inflate(20.0))
        : rect.inflate(20.0);
  }

  void addShapeRect(Rect worldRect) {
    addRect(worldRect);
  }

  Rect? get dirtyBounds => _accumulatedBounds;

  bool get hasDirtyRects => _accumulatedBounds != null;

  void clear() {
    _accumulatedBounds = null;
  }
}
