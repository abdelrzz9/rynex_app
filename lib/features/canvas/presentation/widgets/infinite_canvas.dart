import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/canvas_engine.dart';
import '../../presentation/providers/canvas_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../../../selection/presentation/providers/selection_provider.dart';

class InfiniteCanvas extends ConsumerWidget {
  const InfiniteCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shapes = ref.watch(shapeListProvider);
    final canvasState = ref.watch(canvasProvider);
    final selection = ref.watch(selectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: CanvasEngine(
            shapes: shapes,
            transform: canvasState.transform,
            selection: selection,
            showGrid: canvasState.showGrid,
            isDark: isDark,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
