import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../engine/canvas_engine.dart';
import '../../engine/picture_recorder_manager.dart';
import '../../presentation/providers/canvas_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../../../selection/presentation/providers/selection_provider.dart';

class InfiniteCanvas extends ConsumerStatefulWidget {
  const InfiniteCanvas({super.key});

  @override
  ConsumerState<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends ConsumerState<InfiniteCanvas> {
  List<ShapeEntity> _previousShapes = [];

  @override
  void initState() {
    super.initState();
    _previousShapes = [];
  }

  @override
  Widget build(BuildContext context) {
    final shapes = ref.watch(shapeListProvider);
    final canvasState = ref.watch(canvasProvider);
    final selection = ref.watch(selectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pictureCache = ref.watch(pictureRecorderManagerProvider);

    _markChangedShapes(shapes, pictureCache);

    return ClipRect(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: CanvasEngine(
            shapes: shapes,
            transform: canvasState.transform,
            selection: selection,
            showGrid: canvasState.showGrid,
            isDark: isDark,
            pictureCache: pictureCache,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _markChangedShapes(List<ShapeEntity> shapes, PictureRecorderManager cache) {
    if (_previousShapes == shapes) return;

    final oldIds = _previousShapes.map((s) => s.id).toSet();
    final newIds = shapes.map((s) => s.id).toSet();

    for (final removedId in oldIds.difference(newIds)) {
      cache.remove(removedId);
    }

    final existingIds = oldIds.intersection(newIds);
    final oldById = {for (final s in _previousShapes) s.id: s};
    for (final shape in shapes) {
      if (existingIds.contains(shape.id)) {
        final old = oldById[shape.id]!;
        if (old.boundingBox != shape.boundingBox ||
            old.rotation != shape.rotation ||
            old.style != shape.style) {
          cache.markDirty(shape.id);
        }
      } else {
        cache.markDirty(shape.id);
      }
    }

    _previousShapes = shapes;
  }
}
