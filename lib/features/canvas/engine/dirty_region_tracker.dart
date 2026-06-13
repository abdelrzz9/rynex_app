import 'package:flutter/material.dart';

class DirtyRegionTracker {
  final Set<Rect> _dirtyRects = {};
  Rect? _accumulatedBounds;

  void addRect(Rect rect) {
    _dirtyRects.add(rect);
    _accumulatedBounds = _accumulatedBounds != null
        ? _accumulatedBounds!.expandToInclude(rect)
        : rect;
  }

  void addShapeRect(Rect worldRect) {
    addRect(worldRect.inflate(20.0));
  }

  Rect? get dirtyBounds => _accumulatedBounds;

  bool get hasDirtyRects => _dirtyRects.isNotEmpty;

  List<Rect> get dirtyRects => _dirtyRects.toList();

  void clear() {
    _dirtyRects.clear();
    _accumulatedBounds = null;
  }

  void mergeRects() {
    if (_dirtyRects.length < 2) return;
    final merged = <Rect>[];
    final sorted = _dirtyRects.toList()
      ..sort((a, b) => a.left.compareTo(b.left));
    var current = sorted.first;
    for (final rect in sorted.skip(1)) {
      if (current.overlaps(rect) || current.expandToInclude(rect).shortestSide < current.shortestSide + rect.shortestSide) {
        current = current.expandToInclude(rect);
      } else {
        merged.add(current);
        current = rect;
      }
    }
    merged.add(current);
    _dirtyRects.clear();
    _dirtyRects.addAll(merged);
    _accumulatedBounds = merged.fold<Rect?>(null, (b, r) => b?.expandToInclude(r) ?? r);
  }
}
