import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/canvas_constants.dart';
import '../../domain/entities/camera.dart';
import '../../domain/entities/canvas_state.dart';
import '../../domain/entities/canvas_transform.dart';
import '../../engine/picture_recorder_manager.dart';

final pictureRecorderManagerProvider = Provider<PictureRecorderManager>((ref) {
  final manager = PictureRecorderManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final canvasProvider =
    StateNotifierProvider<CanvasNotifier, CanvasState>(
  (ref) => CanvasNotifier(),
);

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());

  void zoomIn(Offset focalPoint) {
    _zoomToPoint(focalPoint, 1.1);
  }

  void zoomOut(Offset focalPoint) {
    _zoomToPoint(focalPoint, 1 / 1.1);
  }

  void zoomToPoint(Offset screenPoint, double delta) {
    final newZoom = (state.transform.zoom * (1 + delta * 0.001))
        .clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    final worldPoint = state.transform.screenToWorld(screenPoint);
    final newPan = screenPoint - worldPoint * newZoom;
    state = state.copyWith(
      transform: state.transform.copyWith(zoom: newZoom, pan: newPan),
    );
  }

  void _zoomToPoint(Offset screenPoint, double factor) {
    final newZoom = (state.transform.zoom * factor)
        .clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    final worldPoint = state.transform.screenToWorld(screenPoint);
    final newPan = screenPoint - worldPoint * newZoom;
    state = state.copyWith(
      transform: state.transform.copyWith(zoom: newZoom, pan: newPan),
    );
  }

  void panBy(Offset delta) {
    state = state.copyWith(
      transform: state.transform.copyWith(pan: state.transform.pan + delta),
    );
  }

  void setZoom(double zoom) {
    state = state.copyWith(
      transform: state.transform.copyWith(
        zoom: zoom.clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom),
      ),
    );
  }

  void resetViewport() {
    state = state.copyWith(
      transform: const CanvasTransform(),
    );
  }

  void zoomToFit(Size screenSize, Rect contentBounds) {
    if (contentBounds.isEmpty) return;
    final scaleX = screenSize.width / contentBounds.width;
    final scaleY = screenSize.height / contentBounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final zoom = (scale * 0.9).clamp(CanvasConstants.minZoom, CanvasConstants.maxZoom);
    final center = contentBounds.center;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    final newPan = screenCenter - center * zoom;
    state = state.copyWith(
      transform: CanvasTransform(zoom: zoom, pan: newPan),
    );
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  void toggleSnap() {
    state = state.copyWith(snapToGrid: !state.snapToGrid);
  }

  void syncFromCamera(Camera camera) {
    state = state.copyWith(
      transform: CanvasTransform(zoom: camera.zoom, pan: camera.pan),
    );
  }
}

final canvasTransformProvider = Provider<CanvasTransform>((ref) {
  return ref.watch(canvasProvider.select((s) => s.transform));
});

final cameraProvider = Provider<Camera>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  return Camera(zoom: transform.zoom, pan: transform.pan);
});

final canvasRepaintKeyProvider = StateProvider<GlobalKey?>((ref) => null);

final screenSizeProvider = StateProvider<Size>((ref) => Size.zero);

final viewportProvider = Provider<Rect>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  final screenSize = ref.watch(screenSizeProvider);
  if (screenSize == Size.zero) return Rect.zero;
  return transform.getVisibleWorldRect(screenSize);
});
