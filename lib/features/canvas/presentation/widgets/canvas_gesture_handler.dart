import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/canvas_constants.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/utils/geometry_utils.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../../../shapes/presentation/providers/active_tool_provider.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/domain/entities/rectangle_shape.dart';
import '../../../shapes/domain/entities/ellipse_shape.dart';
import '../../../shapes/domain/entities/diamond_shape.dart';
import '../../../shapes/domain/entities/triangle_shape.dart';
import '../../../shapes/domain/entities/line_shape.dart';
import '../../../shapes/domain/entities/arrow_shape.dart';
import '../../../shapes/domain/entities/freehand_shape.dart';
import '../../../shapes/domain/entities/text_shape.dart';
import '../../../shapes/domain/entities/image_shape.dart';
import '../../../shapes/domain/entities/shape.dart';
import '../../../shapes/domain/entities/shape_type.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
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
      _handleAddText(details.localPosition);
    } else if (tool == DrawingTool.image) {
      _handleAddImage(details.localPosition);
    }
  }

  void _handleSelectStart(ScaleStartDetails details) {
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(details.localFocalPoint);
    final shapes = ref.read(shapeListProvider);
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
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(details.localFocalPoint);
    final selection = ref.read(selectionProvider);

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

  void _finishSelect() {
    final selection = ref.read(selectionProvider);
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
        final shape = FreehandShape(id: UuidGenerator.generate(), points: simplified, style: style);
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
        shape = RectangleShape(id: id, boundingBox: normalizedRect, style: style);
      case DrawingTool.ellipse:
        shape = EllipseShape(id: id, boundingBox: normalizedRect, style: style);
      case DrawingTool.diamond:
        shape = DiamondShape(id: id, boundingBox: normalizedRect, style: style);
      case DrawingTool.triangle:
        shape = TriangleShape(id: id, boundingBox: normalizedRect, style: style);
      case DrawingTool.line:
        shape = LineShape(id: id, startPoint: _drawStart!, endPoint: _drawCurrent!, style: style);
      case DrawingTool.arrow:
        shape = ArrowShape(id: id, startPoint: _drawStart!, endPoint: _drawCurrent!, style: style);
      default:
        break;
    }

    if (shape != null) {
      ref.read(historyProvider.notifier).executeAdd(shape);
    }
  }

  void _handleAddText(Offset screenPoint) {
    final transform = ref.read(canvasTransformProvider);
    final worldPoint = transform.screenToWorld(screenPoint);
    final style = ref.read(activeStyleProvider);
    final id = UuidGenerator.generate();
    final shape = TextShape(
      id: id,
      boundingBox: Rect.fromCenter(center: worldPoint, width: 200, height: 40),
      text: 'Text',
      style: style.copyWith(
        strokeColor: style.strokeColor,
        fillColor: Colors.transparent,
      ),
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
    );
    ref.read(historyProvider.notifier).executeAdd(shape);
    ref.read(activeToolProvider.notifier).state = DrawingTool.select;
    ref.read(selectionProvider.notifier).select(id);
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
