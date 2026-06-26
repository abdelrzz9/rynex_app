import 'dart:math';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/canvas_constants.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../../core/utils/geometry_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../history/domain/commands/command.dart';
import '../../../history/domain/commands/composite_command.dart';
import '../../../history/domain/commands/modify_shape_command.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../layers/domain/entities/layer.dart';
import '../../../layers/presentation/providers/layer_provider.dart';
import '../../../selection/domain/entities/selection_state.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../shapes/domain/entities/arrow_shape.dart';
import '../../../shapes/domain/entities/diamond_shape.dart';
import '../../../shapes/domain/entities/ellipse_shape.dart';
import '../../../shapes/domain/entities/freehand_shape.dart';
import '../../../shapes/domain/entities/image_shape.dart';
import '../../../shapes/domain/entities/line_shape.dart';
import '../../../shapes/domain/entities/polygon_shape.dart';
import '../../../shapes/domain/entities/rectangle_shape.dart';
import '../../../shapes/domain/entities/shape.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/domain/entities/shape_type.dart';
import '../../../shapes/domain/entities/text_shape.dart';
import '../../../shapes/domain/entities/triangle_shape.dart';
import '../../../shapes/presentation/providers/active_tool_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../providers/active_drawing_provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/drag_offset_provider.dart';

class CanvasGestureHandler extends ConsumerStatefulWidget {
  final Widget child;
  final bool drawingEnabled;

  const CanvasGestureHandler({required this.child, this.drawingEnabled = false, super.key});

  @override
  ConsumerState<CanvasGestureHandler> createState() => _CanvasGestureHandlerState();
}

class _CanvasGestureHandlerState extends ConsumerState<CanvasGestureHandler> {
  Offset? _drawStart;
  Offset? _drawCurrent;
  List<Offset> _freehandPoints = [];
  Offset? _initialDragStart;
  Map<String, Offset> _selectedShapePositions = {};
  Offset? _panStart;

  // Resize/rotate state
  String? _resizeShapeId;
  ShapeEntity? _resizeOldState;
  Offset? _resizeStartWorldPoint;

  bool get _isShiftPressed => HardwareKeyboard.instance.isShiftPressed;
  bool get _isCtrlPressed => HardwareKeyboard.instance.isControlPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      onTapUp: _onTapUp,
      onDoubleTapDown: _onDoubleTapDown,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    final tool = ref.read(activeToolProvider);
    if (tool == DrawingTool.select) {
      _handleSelectStart(details);
    } else if (tool == DrawingTool.hand) {
      _panStart = details.localFocalPoint;
    } else if (tool == DrawingTool.eraser) {
      _handleDrawStart(details);
    } else {
      _handleDrawStart(details);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final tool = ref.read(activeToolProvider);
    if (tool == DrawingTool.select) {
      _handleSelectUpdate(details);
    } else if (tool == DrawingTool.hand) {
      if (_panStart != null) {
        final delta = details.localFocalPoint - _panStart!;
        ref.read(canvasProvider.notifier).panBy(delta);
        _panStart = details.localFocalPoint;
      }
    } else if (_drawStart != null) {
      _handleDrawUpdate(details);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final tool = ref.read(activeToolProvider);
    if (tool == DrawingTool.select) {
      _finishSelect();
    } else if (tool == DrawingTool.hand) {
      _panStart = null;
    } else if (_drawStart != null && _drawCurrent != null) {
      _finishDrawing(tool);
    }

    _drawStart = null;
    _drawCurrent = null;
    _freehandPoints = [];
    _initialDragStart = null;
    _selectedShapePositions = {};
    _resizeShapeId = null;
    _resizeOldState = null;
    _resizeStartWorldPoint = null;

    ref.read(dragOffsetProvider.notifier).state = {};
    ref.read(activeDrawingProvider.notifier).state = const ActiveDrawingState();
  }

  void _onTapUp(TapUpDetails details) {
    final tool = ref.read(activeToolProvider);
    if (tool == DrawingTool.select) {
      _handleTapSelect(details.localPosition);
    } else if (tool == DrawingTool.text) {
      _handleAddText(details.localPosition, withDialog: true);
    } else if (tool == DrawingTool.image) {
      _handleAddImage(details.localPosition);
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final tool = ref.read(activeToolProvider);
    if (tool == DrawingTool.select) {
      _handleDoubleTapSelect(details.localPosition);
    }
  }

  void _handleDoubleTapSelect(Offset screenPoint) {
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(screenPoint);
    final shapes = ref.read(shapeListProvider);
    final hitShape = _hitTestTopmost(shapes, worldPoint);
    if (hitShape is TextShape) {
      _showTextEditDialog(hitShape);
    }
  }

  void _showTextEditDialog(TextShape shape) {
    final controller = TextEditingController(text: shape.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          decoration: const InputDecoration(labelText: 'Text content'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newText = controller.text;
              if (newText != shape.text) {
                final updated = shape.copyWith(text: newText);
                ref.read(historyProvider.notifier).executeModify(shape.id, shape, updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  HandleType? _hitTestHandle(Offset screenPoint) {
    final selection = ref.read(selectionProvider);
    if (!selection.isSingle || selection.isEmpty) return null;

    final shapes = ref.read(shapeListProvider);
    final shapeId = selection.selectedIds.first;
    ShapeEntity? shape;
    for (final s in shapes) {
      if (s.id == shapeId) { shape = s; break; }
    }
    if (shape == null) return null;

    if (shape.type == ShapeType.line || shape.type == ShapeType.arrow || shape.type == ShapeType.freehand) return null;

    final transform = ref.read(canvasTransformProvider);
    final screenRect = transform.worldToScreenRect(shape.rotatedBoundingBox);

    const threshold = CanvasConstants.handleSize / 2 + 4;

    final topLeft = screenRect.topLeft;
    final topCenter = Offset(screenRect.center.dx, screenRect.top);
    if ((topCenter - screenPoint).distance <= threshold) return HandleType.topCenter;
    final topRight = screenRect.topRight;
    if ((topRight - screenPoint).distance <= threshold) return HandleType.topRight;
    final midLeft = Offset(screenRect.left, screenRect.center.dy);
    if ((midLeft - screenPoint).distance <= threshold) return HandleType.midLeft;
    final midRight = Offset(screenRect.right, screenRect.center.dy);
    if ((midRight - screenPoint).distance <= threshold) return HandleType.midRight;
    final bottomLeft = screenRect.bottomLeft;
    if ((bottomLeft - screenPoint).distance <= threshold) return HandleType.bottomLeft;
    final bottomCenter = Offset(screenRect.center.dx, screenRect.bottom);
    if ((bottomCenter - screenPoint).distance <= threshold) return HandleType.bottomCenter;
    final bottomRight = screenRect.bottomRight;
    if ((bottomRight - screenPoint).distance <= threshold) return HandleType.bottomRight;
    if ((topLeft - screenPoint).distance <= threshold) return HandleType.topLeft;

    final rotationPos = Offset(screenRect.center.dx, screenRect.top - 24);
    if ((rotationPos - screenPoint).distance <= CanvasConstants.rotationHandleSize / 2 + 4) {
      return HandleType.rotation;
    }

    return null;
  }

  void _handleSelectStart(ScaleStartDetails details) {
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(details.localFocalPoint);
    final shapes = ref.read(shapeListProvider);

    final handle = _hitTestHandle(details.localFocalPoint);
    if (handle != null) {
      final selection = ref.read(selectionProvider);
      final selectedId = selection.selectedIds.first;
      final idx = shapes.indexWhere((s) => s.id == selectedId);
      if (idx == -1) return;
      final shape = shapes[idx];
      _resizeShapeId = selectedId;
      _resizeOldState = shape;
      _resizeStartWorldPoint = worldPoint;
      ref.read(selectionProvider.notifier).setActiveHandle(handle, details.localFocalPoint);
      return;
    }

    final hitShape = _hitTestTopmost(shapes, worldPoint);

    if (hitShape != null) {
      final selection = ref.read(selectionProvider);

      if (_isShiftPressed) {
        ref.read(selectionProvider.notifier).toggleSelect(hitShape.id);
      } else if (!selection.isSelected(hitShape.id)) {
        ref.read(selectionProvider.notifier).select(hitShape.id);
      }

      _initialDragStart = worldPoint;
      _selectedShapePositions = {};
      final selectedIds = ref.read(selectionProvider).selectedIds;
      for (final s in shapes) {
        if (selectedIds.contains(s.id)) {
          _selectedShapePositions[s.id] = s.boundingBox.center;
        }
      }
    } else {
      if (!_isShiftPressed) {
        ref.read(selectionProvider.notifier).deselectAll();
      }
      _initialDragStart = worldPoint;
      ref.read(selectionProvider.notifier).startMarquee(details.localFocalPoint);
    }
  }

  void _handleSelectUpdate(ScaleUpdateDetails details) {
    final selection = ref.read(selectionProvider);

    if (selection.hasActiveHandle && _resizeShapeId != null) {
      _handleResizeUpdate(details);
      return;
    }

    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(details.localFocalPoint);

    if (selection.hasMarquee) {
      ref.read(selectionProvider.notifier).updateMarquee(details.localFocalPoint);
    } else if (selection.isNotEmpty && _initialDragStart != null) {
      final totalDelta = worldPoint - _initialDragStart!;
      final overrides = <String, Offset>{};
      for (final id in _selectedShapePositions.keys) {
        overrides[id] = totalDelta;
      }
      ref.read(dragOffsetProvider.notifier).state = overrides;
    }
  }

  void _handleResizeUpdate(ScaleUpdateDetails details) {
    final selection = ref.read(selectionProvider);
    final handle = selection.activeHandle;
    if (handle == null || _resizeStartWorldPoint == null || _resizeOldState == null) return;

    final transform = ref.read(canvasTransformProvider);
    final currentWorldPoint = transform.screenToWorld(details.localFocalPoint);
    final deltaWorld = currentWorldPoint - _resizeStartWorldPoint!;
    final shapes = ref.read(shapeListProvider);
    ShapeEntity? shape;
    for (final s in shapes) {
      if (s.id == _resizeShapeId) { shape = s; break; }
    }
    if (shape == null) return;

    if (handle == HandleType.rotation) {
      final center = shape.boundingBox.center;
      final startAngle = atan2(
        _resizeStartWorldPoint!.dy - center.dy,
        _resizeStartWorldPoint!.dx - center.dx,
      );
      final currentAngle = atan2(
        currentWorldPoint.dy - center.dy,
        currentWorldPoint.dx - center.dx,
      );
      final deltaAngle = currentAngle - startAngle;
      final newRotation = (_resizeOldState!.rotation + deltaAngle) % (2 * pi);
      final updated = shape.copyWith(rotation: newRotation);
      ref.read(shapeListProvider.notifier).updateShape(_resizeShapeId!, updated);
    } else {
      final bounds = _resizeOldState!.boundingBox;
      double left = bounds.left, top = bounds.top, right = bounds.right, bottom = bounds.bottom;

      switch (handle) {
        case HandleType.topLeft:
          left += deltaWorld.dx; top += deltaWorld.dy; break;
        case HandleType.topCenter:
          top += deltaWorld.dy; break;
        case HandleType.topRight:
          right += deltaWorld.dx; top += deltaWorld.dy; break;
        case HandleType.midLeft:
          left += deltaWorld.dx; break;
        case HandleType.midRight:
          right += deltaWorld.dx; break;
        case HandleType.bottomLeft:
          left += deltaWorld.dx; bottom += deltaWorld.dy; break;
        case HandleType.bottomCenter:
          bottom += deltaWorld.dy; break;
        case HandleType.bottomRight:
          right += deltaWorld.dx; bottom += deltaWorld.dy; break;
        default:
          break;
      }

      if (right - left < 5 || bottom - top < 5) return;

      final newRect = Rect.fromLTRB(left, top, right, bottom);
      final updated = shape.copyWith(boundingBox: newRect);
      ref.read(shapeListProvider.notifier).updateShape(_resizeShapeId!, updated);
    }
  }

  void _finishSelect() {
    final selection = ref.read(selectionProvider);
    if (selection.hasActiveHandle && _resizeShapeId != null && _resizeOldState != null) {
      ShapeEntity? currentShape;
      for (final s in ref.read(shapeListProvider)) {
        if (s.id == _resizeShapeId) { currentShape = s; break; }
      }
      if (currentShape != null) {
        ref.read(historyProvider.notifier).executeModify(_resizeShapeId!, _resizeOldState!, currentShape);
      }
      ref.read(selectionProvider.notifier).clearActiveHandle();
      _resizeShapeId = null;
      _resizeOldState = null;
      _resizeStartWorldPoint = null;
      return;
    }

    final overrides = ref.read(dragOffsetProvider);
    if (overrides.isNotEmpty) {
      final shapes = ref.read(shapeListProvider);
      final commands = <Command>[];
      for (final entry in overrides.entries) {
        final idx = shapes.indexWhere((s) => s.id == entry.key);
        if (idx == -1) continue;
        final shape = shapes[idx];
        final newBoxOld = shape.boundingBox.translate(entry.value.dx, entry.value.dy);
        final updated = shape.copyWith(boundingBox: newBoxOld);
        commands.add(ModifyShapeCommand(
          shapeId: entry.key,
          oldState: shape,
          newState: updated,
          onUpdate: (id, s) => ref.read(shapeListProvider.notifier).updateShape(id, s),
        ));
      }
      if (commands.length == 1) {
        ref.read(historyProvider.notifier).execute(commands.first);
      } else if (commands.length > 1) {
        ref.read(historyProvider.notifier).execute(CompositeCommand(commands));
      }
      ref.read(dragOffsetProvider.notifier).state = {};
    }

    if (selection.hasMarquee) {
      final worldMarquee = ref.read(canvasTransformProvider).screenToWorldRect(selection.marqueeRect!);
      final shapes = ref.read(shapeListProvider);
      final hitIds = shapes.where((s) => worldMarquee.overlaps(s.rotatedBoundingBox)).map((s) => s.id).toList();
      ref.read(selectionProvider.notifier).endMarquee(hitIds);
    }
  }

  void _handleTapSelect(Offset screenPoint) {
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(screenPoint);
    final shapes = ref.read(shapeListProvider);
    final hitShape = _hitTestTopmost(shapes, worldPoint);

    if (hitShape != null) {
      if (_isShiftPressed || _isCtrlPressed) {
        ref.read(selectionProvider.notifier).toggleSelect(hitShape.id);
      } else {
        ref.read(selectionProvider.notifier).select(hitShape.id);
      }
    } else {
      if (!_isShiftPressed && !_isCtrlPressed) {
        ref.read(selectionProvider.notifier).deselectAll();
      }
    }
  }

  void _handleDrawStart(ScaleStartDetails details) {
    final transform = ref.read(canvasTransformProvider);
    final tool = ref.read(activeToolProvider);
    final style = ref.read(activeStyleProvider);
    final point = transform.screenToWorld(details.localFocalPoint);
    _drawStart = point;
    _drawCurrent = point;

    if (tool == DrawingTool.freehand || tool.isDrawingTool || tool == DrawingTool.eraser) {
      _freehandPoints = [_drawStart!];
    }

    ref.read(activeDrawingProvider.notifier).state = ActiveDrawingState(
      start: _drawStart,
      end: _drawStart,
      style: style,
      type: tool.toShapeType(),
      points: List.from(_freehandPoints),
    );
  }

  void _handleDrawUpdate(ScaleUpdateDetails details) {
    final transform = ref.read(canvasTransformProvider);
    final tool = ref.read(activeToolProvider);
    final point = transform.screenToWorld(details.localFocalPoint);
    _drawCurrent = point;

    if (tool == DrawingTool.freehand || tool.isDrawingTool || tool == DrawingTool.eraser) {
      _freehandPoints.add(_drawCurrent!);
    }

    ref.read(activeDrawingProvider.notifier).state = ActiveDrawingState(
      start: _drawStart,
      end: _drawCurrent,
      style: ref.read(activeStyleProvider),
      type: tool.toShapeType(),
      points: List.from(_freehandPoints),
    );
  }

  void _finishDrawing(DrawingTool tool) {
    if (_drawStart == null || _drawCurrent == null) return;
    final style = ref.read(activeStyleProvider);

    if (tool == DrawingTool.freehand || tool.isDrawingTool) {
      if (_freehandPoints.length >= 3) {
        final simplified = simplifyPoints(_freehandPoints, CanvasConstants.freehandSimplifyEpsilon);
        final drawStyle = _styleForTool(tool, style);
        final shape = FreehandShape(id: UuidGenerator.generate(), points: simplified, style: drawStyle, layer: _activeLayerInfo());
        ref.read(historyProvider.notifier).executeAdd(shape);
      }
      return;
    }

    if (tool == DrawingTool.eraser && _freehandPoints.length >= 2) {
      _eraseShapes();
      return;
    }

    final rect = Rect.fromPoints(_drawStart!, _drawCurrent!);
    if (rect.width.abs() < 3 && rect.height.abs() < 3) return;

    final normalizedRect = Rect.fromPoints(
      Offset(rect.left < rect.right ? rect.left : rect.right, rect.top < rect.bottom ? rect.top : rect.bottom),
      Offset(rect.left > rect.right ? rect.left : rect.right, rect.top > rect.bottom ? rect.top : rect.bottom),
    );

    final id = UuidGenerator.generate();
    ShapeEntity? shape;

    switch (tool) {
      case DrawingTool.rectangle:
        shape = RectangleShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
      case DrawingTool.roundedRect:
        shape = RectangleShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo(), cornerRadius: 12);
      case DrawingTool.ellipse:
        shape = EllipseShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
      case DrawingTool.diamond:
        shape = DiamondShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
      case DrawingTool.triangle:
        shape = TriangleShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
      case DrawingTool.polygon:
        shape = PolygonShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
      case DrawingTool.line:
        shape = LineShape(id: id, startPoint: _drawStart!, endPoint: _drawCurrent!, style: style, layer: _activeLayerInfo());
      case DrawingTool.arrow:
        shape = ArrowShape(id: id, startPoint: _drawStart!, endPoint: _drawCurrent!, style: style, layer: _activeLayerInfo());
      default:
        break;
    }

    if (shape != null) {
      ref.read(historyProvider.notifier).executeAdd(shape);
    }
  }

  ShapeStyle _styleForTool(DrawingTool tool, ShapeStyle base) {
    switch (tool) {
      case DrawingTool.pencil:
        return base.copyWith(strokeWidth: 1.5, opacity: 0.9);
      case DrawingTool.pen:
        return base.copyWith(strokeWidth: 3.0, opacity: 1.0);
      case DrawingTool.marker:
        return base.copyWith(strokeWidth: 8.0, opacity: 0.5);
      case DrawingTool.brush:
        return base.copyWith(strokeWidth: 5.0, opacity: 0.8);
      default:
        return base;
    }
  }

  void _handleAddText(Offset screenPoint, {bool withDialog = false}) {
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(screenPoint);
    final style = ref.read(activeStyleProvider);
    final id = UuidGenerator.generate();
    const initialText = 'Text';

    if (withDialog) {
      final controller = TextEditingController(text: initialText);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Text'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            minLines: 1,
            decoration: const InputDecoration(labelText: 'Text content'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final text = controller.text;
                if (text.trim().isNotEmpty) {
                  final shape = TextShape(
                    id: id,
                    boundingBox: Rect.fromCenter(center: worldPoint, width: 200, height: 40),
                    text: text,
                    style: style.copyWith(
                      strokeColor: style.strokeColor,
                      fillColor: Colors.transparent,
                    ),
                    layer: _activeLayerInfo(),
                  );
                  ref.read(historyProvider.notifier).executeAdd(shape);
                  ref.read(activeToolProvider.notifier).state = DrawingTool.select;
                  ref.read(selectionProvider.notifier).select(id);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
      return;
    }

    final shape = TextShape(
      id: id,
      boundingBox: Rect.fromCenter(center: worldPoint, width: 200, height: 40),
      text: initialText,
      style: style.copyWith(
        strokeColor: style.strokeColor,
        fillColor: Colors.transparent,
      ),
      layer: _activeLayerInfo(),
    );
    ref.read(historyProvider.notifier).executeAdd(shape);
    ref.read(activeToolProvider.notifier).state = DrawingTool.select;
    ref.read(selectionProvider.notifier).select(id);
  }

  Future<void> _handleAddImage(Offset screenPoint) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) return;

    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(screenPoint);

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final decodedImage = frame.image;
    final originalSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

    const maxDim = 300.0;
    final scale = min(maxDim / originalSize.width, maxDim / originalSize.height);
    final displaySize = Size(originalSize.width * scale, originalSize.height * scale);

    final id = UuidGenerator.generate();
    final pictureCache = ref.read(pictureRecorderManagerProvider);
    pictureCache.cacheImage(id, decodedImage);

    final shape = ImageShape(
      id: id,
      boundingBox: Rect.fromCenter(center: worldPoint, width: displaySize.width, height: displaySize.height),
      imageBytes: bytes,
      originalSize: originalSize,
      layer: _activeLayerInfo(),
    );
    ref.read(historyProvider.notifier).executeAdd(shape);
    ref.read(activeToolProvider.notifier).state = DrawingTool.select;
    ref.read(selectionProvider.notifier).select(id);
  }

  LayerInfo _activeLayerInfo() {
    final layers = ref.read(layerListProvider);
    final activeId = ref.read(activeLayerIdProvider);
    LayerEntity? active;
    for (final l in layers) {
      if (l.id == activeId) { active = l; break; }
    }
    active ??= layers.last;
    return LayerInfo(
      order: active.order,
      isVisible: active.isVisible,
      isLocked: active.isLocked,
      name: active.name,
    );
  }

  void _eraseShapes() {
    final shapes = ref.read(shapeListProvider);
    final toRemove = <ShapeEntity>[];
    const eraserSize = 15.0;

    for (final shape in shapes) {
      if (!shape.isVisible || shape.isLocked) continue;
      for (final point in _freehandPoints) {
        final padded = shape.rotatedBoundingBox.inflate(eraserSize);
        if (padded.contains(point)) {
          toRemove.add(shape);
          break;
        }
      }
    }

    if (toRemove.isNotEmpty) {
      ref.read(historyProvider.notifier).executeDelete(toRemove);
    }
  }

  ShapeEntity? _hitTestTopmost(List<ShapeEntity> shapes, Offset worldPoint) {
    for (var i = shapes.length - 1; i >= 0; i--) {
      final shape = shapes[i];
      if (!shape.isVisible || shape.isLocked) continue;
      if (shape.hitTest(worldPoint)) return shape;
    }
    return null;
  }
}
