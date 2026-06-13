import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../shapes/presentation/providers/active_tool_provider.dart';
import '../../domain/entities/camera.dart';
import '../providers/canvas_provider.dart';
import 'canvas_gesture_handler.dart';
import 'infinite_canvas.dart';

class CanvasViewport extends ConsumerStatefulWidget {
  const CanvasViewport({super.key});

  @override
  ConsumerState<CanvasViewport> createState() => _CanvasViewportState();
}

class _CanvasViewportState extends ConsumerState<CanvasViewport> {
  final TransformationController _transformationController =
      TransformationController();
  Camera? _lastCamera;

  @override
  void initState() {
    super.initState();
    _lastCamera = ref.read(cameraProvider);
    _transformationController.value = _lastCamera!.toMatrix4();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final matrix = _transformationController.value;
    final camera = Camera.fromMatrix4(matrix);
    _lastCamera = camera;
    ref.read(canvasProvider.notifier).syncFromCamera(camera);
  }

  @override
  Widget build(BuildContext context) {
    final camera = ref.watch(cameraProvider);
    if (_lastCamera != camera) {
      _lastCamera = camera;
      _transformationController.value = camera.toMatrix4();
    }

    final activeTool = ref.watch(activeToolProvider);
    final isDrawing = activeTool != DrawingTool.select;

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(screenSizeProvider.notifier).state =
              Size(constraints.maxWidth, constraints.maxHeight);
        });

        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 10.0,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          onInteractionEnd: _onInteractionEnd,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: CanvasGestureHandler(
              drawingEnabled: isDrawing,
              child: const InfiniteCanvas(),
            ),
          ),
        );
      },
    );
  }
}
