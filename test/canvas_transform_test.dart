import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/features/canvas/domain/entities/canvas_transform.dart';

void main() {
  group('CanvasTransform', () {
    test('default transform is identity', () {
      const t = CanvasTransform();
      expect(t.zoom, 1.0);
      expect(t.pan, Offset.zero);
    });

    test('screenToWorld inverts transform', () {
      const t = CanvasTransform(zoom: 2.0, pan: Offset(100, 50));
      final world = t.screenToWorld(const Offset(200, 100));
      expect(world.dx, 50);
      expect(world.dy, 25);
    });

    test('worldToScreen applies transform', () {
      const t = CanvasTransform(zoom: 2.0, pan: Offset(100, 50));
      final screen = t.worldToScreen(const Offset(50, 25));
      expect(screen.dx, 200);
      expect(screen.dy, 100);
    });

    test('screenToWorldRect inverts transform for rect', () {
      const t = CanvasTransform(zoom: 2.0, pan: Offset(100, 50));
      final world = t.screenToWorldRect(const Rect.fromLTWH(100, 50, 200, 100));
      expect(world.left, 0);
      expect(world.top, 0);
      expect(world.width, 100);
      expect(world.height, 50);
    });

    test('worldToScreenRect applies transform for rect', () {
      const t = CanvasTransform(zoom: 2.0, pan: Offset(100, 50));
      final screen = t.worldToScreenRect(const Rect.fromLTWH(0, 0, 100, 50));
      expect(screen.left, 100);
      expect(screen.top, 50);
      expect(screen.width, 200);
      expect(screen.height, 100);
    });

    test('getVisibleWorldRect computes visible area', () {
      const t = CanvasTransform(zoom: 2.0, pan: Offset(100, 50));
      final visible = t.getVisibleWorldRect(const Size(400, 300));
      expect(visible.left, -50);
      expect(visible.top, -25);
      expect(visible.width, 200);
      expect(visible.height, 150);
    });

    test('copyWith updates zoom', () {
      const t = CanvasTransform(zoom: 1.0);
      final updated = t.copyWith(zoom: 2.5);
      expect(updated.zoom, 2.5);
      expect(updated.pan, Offset.zero);
    });
  });
}
