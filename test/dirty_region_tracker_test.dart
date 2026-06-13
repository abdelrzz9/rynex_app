import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/features/canvas/engine/dirty_region_tracker.dart';

void main() {
  group('DirtyRegionTracker', () {
    late DirtyRegionTracker tracker;

    setUp(() {
      tracker = DirtyRegionTracker();
    });

    test('starts empty', () {
      expect(tracker.hasDirtyRects, false);
      expect(tracker.dirtyBounds, isNull);
    });

    test('addRect adds a rect', () {
      tracker.addRect(const Rect.fromLTWH(0, 0, 100, 50));
      expect(tracker.hasDirtyRects, true);
      expect(tracker.dirtyBounds, const Rect.fromLTWH(0, 0, 100, 50));
    });

    test('addShapeRect inflates rect', () {
      tracker.addShapeRect(const Rect.fromLTWH(0, 0, 100, 50));
      expect(tracker.dirtyBounds, const Rect.fromLTWH(-20, -20, 140, 90));
    });

    test('accumulates multiple rects', () {
      tracker.addRect(const Rect.fromLTWH(0, 0, 100, 50));
      tracker.addRect(const Rect.fromLTWH(200, 0, 100, 50));
      expect(tracker.dirtyBounds, const Rect.fromLTWH(0, 0, 300, 50));
    });

    test('clear removes all', () {
      tracker.addRect(const Rect.fromLTWH(0, 0, 100, 50));
      tracker.clear();
      expect(tracker.hasDirtyRects, false);
      expect(tracker.dirtyBounds, isNull);
    });

    test('mergeRects merges overlapping rects', () {
      tracker.addRect(const Rect.fromLTWH(0, 0, 60, 50));
      tracker.addRect(const Rect.fromLTWH(50, 0, 60, 50));
      tracker.mergeRects();
      expect(tracker.dirtyRects.length, lessThanOrEqualTo(2));
      expect(tracker.dirtyBounds, const Rect.fromLTWH(0, 0, 110, 50));
    });
  });
}
