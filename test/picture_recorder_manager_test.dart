import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/features/canvas/engine/picture_recorder_manager.dart';

ui.Picture _makePicture() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(ui.Offset.zero & const ui.Size(10, 10), ui.Paint());
  return recorder.endRecording();
}

void main() {
  group('PictureRecorderManager', () {
    test('returns null for unknown id', () {
      final manager = PictureRecorderManager();
      expect(manager.get('unknown'), isNull);
      manager.dispose();
    });

    test('caches and retrieves picture', () {
      final manager = PictureRecorderManager();
      final picture = _makePicture();
      manager.cache('shape1', picture);
      expect(manager.get('shape1'), picture);
      manager.dispose();
    });

    test('returns null for dirty id', () {
      final manager = PictureRecorderManager();
      final picture = _makePicture();
      manager.cache('shape1', picture);
      manager.markDirty('shape1');
      expect(manager.get('shape1'), isNull);
      manager.dispose();
    });

    test('isDirty returns correct state', () {
      final manager = PictureRecorderManager();
      expect(manager.isDirty('shape1'), false);
      manager.markDirty('shape1');
      expect(manager.isDirty('shape1'), true);
      manager.dispose();
    });

    test('removes picture', () {
      final manager = PictureRecorderManager();
      final picture = _makePicture();
      manager.cache('shape1', picture);
      manager.remove('shape1');
      expect(manager.get('shape1'), isNull);
      expect(manager.isDirty('shape1'), false);
      manager.dispose();
    });

    test('markAllDirty marks all cached', () {
      final manager = PictureRecorderManager();
      final picture = _makePicture();
      manager.cache('shape1', picture);
      manager.markAllDirty();
      expect(manager.isDirty('shape1'), true);
      manager.dispose();
    });

    test('clear removes all', () {
      final manager = PictureRecorderManager();
      final picture = _makePicture();
      manager.cache('shape1', picture);
      manager.clear();
      expect(manager.get('shape1'), isNull);
      manager.dispose();
    });

    test('cacheImage/getImage roundtrip', () async {
      final manager = PictureRecorderManager();
      final picture = _makePicture();
      final image = await picture.toImage(10, 10);
      manager.cacheImage('img1', image);
      expect(manager.getImage('img1'), image);
      manager.remove('img1');
      expect(manager.getImage('img1'), isNull);
      picture.dispose();
      manager.dispose();
    });
  });
}
