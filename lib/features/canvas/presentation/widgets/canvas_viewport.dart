import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../shapes/presentation/providers/active_tool_provider.dart';
import '../providers/canvas_controller_provider.dart';
import '../providers/canvas_provider.dart';
import 'canvas_gesture_handler.dart';
import 'infinite_canvas.dart';

class CanvasViewport extends ConsumerStatefulWidget {
  const CanvasViewport({super.key});

  @override
  ConsumerState<CanvasViewport> createState() => _CanvasViewportState();
}

class _CanvasViewportState extends ConsumerState<CanvasViewport> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScreenSize());
  }

  void _updateScreenSize() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      ref.read(screenSizeProvider.notifier).state = renderBox.size;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTool = ref.watch(activeToolProvider);
    final controller = ref.watch(canvasControllerProvider);
    final isDrawing = activeTool != DrawingTool.select;

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(screenSizeProvider.notifier).state = Size(constraints.maxWidth, constraints.maxHeight);
        });

        return InteractiveViewer(
          transformationController: controller.transformationController,
          minScale: 0.1,
          maxScale: 10.0,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
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
