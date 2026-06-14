import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../../engine/canvas_engine.dart';
import '../../engine/dirty_region_tracker.dart';
import '../../engine/picture_recorder_manager.dart';
import '../providers/active_drawing_provider.dart';
import '../providers/canvas_provider.dart';

class InfiniteCanvas extends ConsumerStatefulWidget {
  const InfiniteCanvas({super.key});

  @override
  ConsumerState<InfiniteCanvas> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends ConsumerState<InfiniteCanvas> {
  List<ShapeEntity> _previousShapes = [];
  final GlobalKey _repaintKey = GlobalKey();
  final DirtyRegionTracker _dirtyRegionTracker = DirtyRegionTracker();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _previousShapes = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && mounted) {
        ref.read(canvasRepaintKeyProvider.notifier).state = _repaintKey;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shapes = ref.watch(shapeListProvider);
    final canvasState = ref.watch(canvasProvider);
    final selection = ref.watch(selectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pictureCache = ref.watch(pictureRecorderManagerProvider);
    final activeDrawing = ref.watch(activeDrawingProvider);

    _markChangedShapes(shapes, pictureCache);

    return ClipRect(
      child: RepaintBoundary(
        key: _repaintKey,
        child: CustomPaint(
          painter: CanvasEngine(
            shapes: shapes,
            transform: canvasState.transform,
            selection: selection,
            showGrid: canvasState.showGrid,
            isDark: isDark,
            canvasWidth: canvasState.canvasWidth,
            canvasHeight: canvasState.canvasHeight,
            pictureCache: pictureCache,
            dirtyRegionTracker: _dirtyRegionTracker,
            activeDrawingStart: activeDrawing.start,
            activeDrawingEnd: activeDrawing.end,
            activeDrawingStyle: activeDrawing.style,
            activeShapeType: activeDrawing.type,
            activeDrawingPoints: activeDrawing.points,
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
      _dirtyRegionTracker.addShapeRect(
        _previousShapes.firstWhere((s) => s.id == removedId).rotatedBoundingBox,
      );
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
          _dirtyRegionTracker.addShapeRect(shape.rotatedBoundingBox);
          _dirtyRegionTracker.addShapeRect(old.rotatedBoundingBox);
        }
      } else {
        cache.markDirty(shape.id);
        _dirtyRegionTracker.addShapeRect(shape.rotatedBoundingBox);
      }
    }

    _previousShapes = shapes;
  }
}
