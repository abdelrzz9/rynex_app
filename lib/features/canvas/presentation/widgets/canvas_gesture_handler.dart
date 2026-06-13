import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/canvas_constants.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../../core/utils/geometry_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
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
import '../../../shapes/domain/entities/rectangle_shape.dart';
import '../../../shapes/domain/entities/shape.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/domain/entities/shape_type.dart';
import '../../../shapes/domain/entities/text_shape.dart';
import '../../../shapes/domain/entities/triangle_shape.dart';
import '../../../shapes/presentation/providers/active_tool_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../providers/canvas_provider.dart';

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
  Offset? _selectionDragStart;
  Map<String, Offset> _selectedShapePositions = {};

  // Resize/rotate state
  String? _resizeShapeId;
  ShapeEntity? _resizeOldState;
  Offset? _resizeStartWorldPoint;

  Offset? activeDrawStart;
  Offset? activeDrawEnd;
  ShapeStyle? activeDrawStyle;
  ShapeType? activeDrawType;

  bool get _isShiftPressed => HardwareKeyboard.instance.isShiftPressed;

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
    } else {
      _handleDrawStart(details);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final tool = ref.read(activeToolProvider);
    if (tool == DrawingTool.select) {
      _handleSelectUpdate(details);
    } else if (_drawStart != null) {
      _handleDrawUpdate(details);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final tool = ref.read(activeToolProvider);
    if (tool == DrawingTool.select) {
      _finishSelect();
    } else if (_drawStart != null && _drawCurrent != null) {
      _finishDrawing(tool);
    }

    _drawStart = null;
    _drawCurrent = null;
    _freehandPoints = [];
    _selectionDragStart = null;
    _selectedShapePositions = {};
    _resizeShapeId = null;
    _resizeOldState = null;
    _resizeStartWorldPoint = null;

    activeDrawStart = null;
    activeDrawEnd = null;
    activeDrawStyle = null;
    activeDrawType = null;
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
      final shape = shapes.firstWhere((s) => s.id == selectedId);
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

      _selectionDragStart = worldPoint;
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
      _selectionDragStart = worldPoint;
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
    } else if (selection.isNotEmpty && _selectionDragStart != null) {
      final delta = worldPoint - _selectionDragStart!;
      final shapes = ref.read(shapeListProvider);

      for (final entry in _selectedShapePositions.entries) {
        final shape = shapes.firstWhere((s) => s.id == entry.key);
        final newBox = shape.boundingBox.translate(delta.dx, delta.dy);
        final updated = shape.copyWith(boundingBox: newBox);
        ref.read(shapeListProvider.notifier).updateShape(shape.id, updated);
      }
      _selectionDragStart = worldPoint;
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
      if (_isShiftPressed) {
        ref.read(selectionProvider.notifier).toggleSelect(hitShape.id);
      } else {
        ref.read(selectionProvider.notifier).select(hitShape.id);
      }
    } else {
      if (!_isShiftPressed) {
        ref.read(selectionProvider.notifier).deselectAll();
      }
    }
  }

  void _handleDrawStart(ScaleStartDetails details) {
    final transform = ref.read(canvasTransformProvider);
    final tool = ref.read(activeToolProvider);
    final style = ref.read(activeStyleProvider);
    _drawStart = transform.screenToWorld(details.localFocalPoint);
    _drawCurrent = _drawStart;

    if (tool == DrawingTool.freehand) {
      _freehandPoints = [_drawStart!];
    }

    activeDrawStart = _drawStart;
    activeDrawEnd = _drawStart;
    activeDrawStyle = style;
    activeDrawType = tool.toShapeType();
    setState(() {});
  }

  void _handleDrawUpdate(ScaleUpdateDetails details) {
    final transform = ref.read(canvasTransformProvider);
    final tool = ref.read(activeToolProvider);
    _drawCurrent = transform.screenToWorld(details.localFocalPoint);

    if (tool == DrawingTool.freehand) {
      _freehandPoints.add(_drawCurrent!);
    }

    activeDrawEnd = _drawCurrent;
    setState(() {});
  }

  void _finishDrawing(DrawingTool tool) {
    if (_drawStart == null || _drawCurrent == null) return;
    final style = ref.read(activeStyleProvider);

    if (tool == DrawingTool.freehand) {
      if (_freehandPoints.length >= 3) {
        final simplified = simplifyPoints(_freehandPoints, CanvasConstants.freehandSimplifyEpsilon);
        final shape = FreehandShape(id: UuidGenerator.generate(), points: simplified, style: style, layer: _activeLayerInfo());
        ref.read(historyProvider.notifier).executeAdd(shape);
      }
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
      case DrawingTool.ellipse:
        shape = EllipseShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
      case DrawingTool.diamond:
        shape = DiamondShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
      case DrawingTool.triangle:
        shape = TriangleShape(id: id, boundingBox: normalizedRect, style: style, layer: _activeLayerInfo());
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

  void _handleAddImage(Offset screenPoint) {
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(screenPoint);
    final id = UuidGenerator.generate();
    final shape = ImageShape(
      id: id,
      boundingBox: Rect.fromCenter(center: worldPoint, width: 100, height: 100),
      imageBytes: Uint8List(0),
      originalSize: const Size(100, 100),
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

  ShapeEntity? _hitTestTopmost(List<ShapeEntity> shapes, Offset worldPoint) {
    for (var i = shapes.length - 1; i >= 0; i--) {
      final shape = shapes[i];
      if (!shape.isVisible || shape.isLocked) continue;
      if (shape.hitTest(worldPoint)) return shape;
    }
    return null;
  }
}
