import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/core/constants/canvas_constants.dart';
import 'package:rynex_app/features/canvas/domain/entities/camera.dart';

void main() {
  group('Camera', () {
    test('default values', () {
      final camera = const Camera();
      expect(camera.zoom, CanvasConstants.defaultZoom);
      expect(camera.pan, Offset.zero);
    });

    test('screenToWorld inverts transform', () {
      final camera = Camera(zoom: 2.0, pan: const Offset(100, 50));
      final world = camera.screenToWorld(const Offset(300, 150));
      expect(world.dx, closeTo(100, 1e-10));
      expect(world.dy, closeTo(50, 1e-10));
    });

    test('worldToScreen applies transform', () {
      final camera = Camera(zoom: 2.0, pan: const Offset(100, 50));
      final screen = camera.worldToScreen(const Offset(100, 50));
      expect(screen.dx, closeTo(300, 1e-10));
      expect(screen.dy, closeTo(150, 1e-10));
    });

    test('screenToWorldRect inverts transform for rect', () {
      final camera = Camera(zoom: 2.0, pan: const Offset(100, 50));
      final worldRect = camera.screenToWorldRect(Rect.fromLTWH(100, 50, 200, 100));
      expect(worldRect.left, closeTo(0, 1e-10));
      expect(worldRect.top, closeTo(0, 1e-10));
      expect(worldRect.width, closeTo(100, 1e-10));
      expect(worldRect.height, closeTo(50, 1e-10));
    });

    test('worldToScreenRect applies transform for rect', () {
      final camera = Camera(zoom: 2.0, pan: const Offset(100, 50));
      final screenRect = camera.worldToScreenRect(Rect.fromLTWH(0, 0, 100, 50));
      expect(screenRect.left, closeTo(100, 1e-10));
      expect(screenRect.top, closeTo(50, 1e-10));
      expect(screenRect.width, closeTo(200, 1e-10));
      expect(screenRect.height, closeTo(100, 1e-10));
    });

    test('getVisibleWorldRect computes visible area', () {
      final camera = Camera(zoom: 2.0, pan: const Offset(100, 50));
      final visible = camera.getVisibleWorldRect(const Size(400, 200));
      expect(visible.left, closeTo(-50, 1e-10));
      expect(visible.top, closeTo(-25, 1e-10));
      expect(visible.width, closeTo(200, 1e-10));
      expect(visible.height, closeTo(100, 1e-10));
    });

    test('zoomToPoint maintains focal point', () {
      final camera = Camera(zoom: 1.0, pan: Offset.zero);
      final result = camera.zoomToPoint(const Offset(200, 100), 2.0);
      expect(result.zoom, 2.0);
      final worldBefore = camera.screenToWorld(const Offset(200, 100));
      final worldAfter = result.screenToWorld(const Offset(200, 100));
      expect(worldBefore.dx, closeTo(worldAfter.dx, 1e-10));
      expect(worldBefore.dy, closeTo(worldAfter.dy, 1e-10));
    });

    test('zoomToPoint clamps zoom within bounds', () {
      final camera = Camera(zoom: 1.0);
      final result = camera.zoomToPoint(Offset.zero, 100);
      expect(result.zoom, CanvasConstants.maxZoom);
      final result2 = camera.zoomToPoint(Offset.zero, -100);
      expect(result2.zoom, CanvasConstants.minZoom);
    });

    test('panBy translates pan', () {
      final camera = Camera(zoom: 1.0, pan: Offset.zero);
      final result = camera.panBy(const Offset(50, 30));
      expect(result.pan, const Offset(50, 30));
      expect(result.zoom, 1.0);
    });

    test('copyWith preserves unchanged values', () {
      final camera = Camera(zoom: 2.0, pan: const Offset(100, 50));
      final result = camera.copyWith(zoom: 3.0);
      expect(result.zoom, 3.0);
      expect(result.pan, const Offset(100, 50));
    });

    test('toMatrix4 and fromMatrix4 roundtrip', () {
      final camera = Camera(zoom: 2.5, pan: const Offset(100, 200));
      final matrix = camera.toMatrix4();
      final restored = Camera.fromMatrix4(matrix);
      expect(restored.zoom, closeTo(2.5, 1e-10));
      expect(restored.pan.dx, closeTo(100, 1e-10));
      expect(restored.pan.dy, closeTo(200, 1e-10));
    });

    test('fromMatrix4 parses identity matrix', () {
      final camera = Camera.fromMatrix4(Matrix4.identity());
      expect(camera.zoom, 1.0);
      expect(camera.pan, Offset.zero);
    });

    test('lerp interpolates between two cameras', () {
      final a = Camera(zoom: 1.0, pan: Offset.zero);
      final b = Camera(zoom: 3.0, pan: const Offset(100, 50));
      final mid = Camera.lerp(a, b, 0.5);
      expect(mid.zoom, closeTo(2.0, 1e-10));
      expect(mid.pan.dx, closeTo(50, 1e-10));
      expect(mid.pan.dy, closeTo(25, 1e-10));
    });

    test('lerp at t=0 returns first camera', () {
      final a = Camera(zoom: 1.0, pan: Offset.zero);
      final b = Camera(zoom: 3.0, pan: const Offset(100, 50));
      expect(Camera.lerp(a, b, 0.0), a);
    });

    test('lerp at t=1 returns second camera', () {
      final a = Camera(zoom: 1.0, pan: Offset.zero);
      final b = Camera(zoom: 3.0, pan: const Offset(100, 50));
      expect(Camera.lerp(a, b, 1.0), b);
    });

    test('equality considers zoom and pan', () {
      expect(
        const Camera(zoom: 2.0, pan: Offset.zero),
        const Camera(zoom: 2.0, pan: Offset.zero),
      );
      expect(
        const Camera(zoom: 2.0, pan: Offset.zero),
        isNot(const Camera(zoom: 1.0, pan: Offset.zero)),
      );
    });

    test('screenToWorld and worldToScreen are inverses', () {
      final camera = Camera(zoom: 1.5, pan: const Offset(50, 25));
      final original = const Offset(123.456, 789.012);
      final screen = camera.worldToScreen(original);
      final world = camera.screenToWorld(screen);
      expect(world.dx, closeTo(original.dx, 1e-10));
      expect(world.dy, closeTo(original.dy, 1e-10));
    });
  });
}
