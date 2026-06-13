import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/canvas_controller.dart';

final canvasControllerProvider = Provider<CanvasController>((ref) {
  final controller = CanvasController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
