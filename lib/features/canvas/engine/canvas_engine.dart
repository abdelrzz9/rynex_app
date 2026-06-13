import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../shapes/domain/entities/shape_entity.dart';
import '../../shapes/domain/entities/rectangle_shape.dart';
import '../../shapes/domain/entities/ellipse_shape.dart';
import '../../shapes/domain/entities/diamond_shape.dart';
import '../../shapes/domain/entities/triangle_shape.dart';
import '../../shapes/domain/entities/line_shape.dart';
import '../../shapes/domain/entities/arrow_shape.dart';
import '../../shapes/domain/entities/freehand_shape.dart';
import '../../shapes/domain/entities/text_shape.dart';
import '../../shapes/domain/entities/image_shape.dart';
import '../../shapes/domain/entities/shape.dart';
import '../../shapes/domain/entities/shape_type.dart';
import '../../shapes/domain/value_objects/roughness.dart';
import '../../shapes/domain/value_objects/fill_style.dart';
import '../../shapes/domain/value_objects/stroke_style.dart';
import '../../selection/domain/entities/selection_state.dart';
import '../domain/entities/canvas_transform.dart';
import '../../../core/constants/canvas_constants.dart';
import 'picture_recorder_manager.dart';

class CanvasEngine extends CustomPainter {
  final List<ShapeEntity> shapes;
  final CanvasTransform transform;
  final SelectionState selection;
  final bool showGrid;
  final bool isDark;
  final Offset? activeDrawingStart;
  final Offset? activeDrawingEnd;
  final ShapeStyle? activeDrawingStyle;
  final ShapeType? activeShapeType;

  final PictureRecorderManager? pictureCache;

  CanvasEngine({
    required this.shapes,
    required this.transform,
    required this.selection,
    this.showGrid = true,
    this.isDark = false,
    this.activeDrawingStart,
    this.activeDrawingEnd,
    this.activeDrawingStyle,
    this.activeShapeType,
    this.pictureCache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);

    if (showGrid) {
      _paintGrid(canvas, size);
    }

    final viewportRect = transform.getVisibleWorldRect(size).inflate(CanvasConstants.cullingPadding);

    canvas.save();
    canvas.translate(transform.pan.dx, transform.pan.dy);
    canvas.scale(transform.zoom);

    final visibleShapes = shapes.where((s) {
      if (!s.isVisible) return false;
      return viewportRect.overlaps(s.rotatedBoundingBox);
    }).toList()
      ..sort((a, b) => a.layer.order.compareTo(b.layer.order));

    for (final shape in visibleShapes) {
      _paintShape(canvas, shape);
    }

    if (activeDrawingStart != null && activeDrawingEnd != null && activeDrawingStyle != null) {
      _paintActiveShape(canvas);
    }

    canvas.restore();

    if (selection.isNotEmpty) {
      _paintSelectionOverlay(canvas, size);
    }

    if (selection.hasMarquee) {
      _paintMarquee(canvas, selection.marqueeRect!);
    }

    canvas.restore();
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 0.5;

    final gridSize = CanvasConstants.gridSize * transform.zoom;
    if (gridSize < 4) return;

    final offset = transform.pan;
    final startX = offset.dx % gridSize - gridSize;
    final startY = offset.dy % gridSize - gridSize;

    for (var x = startX; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = startY; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintShape(Canvas canvas, ShapeEntity shape) {
    final cached = pictureCache?.get(shape.id);
    if (cached != null) {
      canvas.save();
      canvas.drawPicture(cached);
      canvas.restore();
      return;
    }

    final recorder = ui.PictureRecorder();
    final recordCanvas = Canvas(recorder);
    recordCanvas.save();

    if (shape.style.opacity < 1.0) {
      recordCanvas.saveLayer(shape.rotatedBoundingBox, Paint()..color = Color.fromRGBO(0, 0, 0, shape.style.opacity));
    }

    recordCanvas.translate(shape.center.dx, shape.center.dy);
    recordCanvas.rotate(shape.rotation);
    recordCanvas.translate(-shape.center.dx, -shape.center.dy);

    switch (shape.type) {
      case ShapeType.rectangle:
      case ShapeType.roundedRect:
        _paintRectangle(recordCanvas, shape as RectangleShape);
      case ShapeType.ellipse:
        _paintEllipse(recordCanvas, shape as EllipseShape);
      case ShapeType.diamond:
        _paintDiamond(recordCanvas, shape as DiamondShape);
      case ShapeType.triangle:
        _paintTriangle(recordCanvas, shape as TriangleShape);
      case ShapeType.line:
        _paintLine(recordCanvas, shape as LineShape);
      case ShapeType.arrow:
        _paintArrow(recordCanvas, shape as ArrowShape);
      case ShapeType.freehand:
        _paintFreehand(recordCanvas, shape as FreehandShape);
      case ShapeType.text:
        _paintText(recordCanvas, shape as TextShape);
      case ShapeType.image:
        _paintImage(recordCanvas, shape as ImageShape);
    }

    if (shape.style.opacity < 1.0) {
      recordCanvas.restore();
    }
    recordCanvas.restore();

    final picture = recorder.endRecording();
    pictureCache?.cache(shape.id, picture);

    canvas.save();
    canvas.drawPicture(picture);
    canvas.restore();
  }

  void _paintRectangle(Canvas canvas, RectangleShape shape) {
    final rect = shape.boundingBox;
    final roughness = shape.style.roughness;

    if (shape.style.fillStyle != FillStyle.none) {
      final fillPaint = Paint()
        ..color = shape.style.fillColor.withValues(alpha: shape.style.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(shape.cornerRadius)),
        fillPaint,
      );
      if (roughness != Roughness.none) {
        _paintRoughFill(canvas, rect, shape.style);
      }
    }

    final iterations = roughness.iterations;
    final jitter = roughness.jitterAmplitude;
    final rng = Random(shape.id.hashCode);

    for (var i = 0; i < iterations; i++) {
      final strokePaint = Paint()
        ..color = shape.style.strokeColor.withValues(alpha: shape.style.opacity)
        ..strokeWidth = shape.style.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (shape.style.strokeStyle == StrokeStyle.dashed) {
        strokePaint.strokeWidth = shape.style.strokeWidth;
      }

      final jittered = Rect.fromLTWH(
        rect.left + _jitter(rng, jitter),
        rect.top + _jitter(rng, jitter),
        rect.width + _jitter(rng, jitter),
        rect.height + _jitter(rng, jitter),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(jittered, Radius.circular(shape.cornerRadius + _jitter(rng, jitter))),
        strokePaint,
      );
    }
  }

  void _paintEllipse(Canvas canvas, EllipseShape shape) {
    final rect = shape.boundingBox;
    final roughness = shape.style.roughness;
    final jitter = roughness.jitterAmplitude;
    final rng = Random(shape.id.hashCode * 13);

    if (shape.style.fillStyle != FillStyle.none) {
      final fillPaint = Paint()
        ..color = shape.style.fillColor.withValues(alpha: shape.style.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawOval(rect, fillPaint);
    }

    final iterations = roughness.iterations;
    for (var i = 0; i < iterations; i++) {
      final strokePaint = Paint()
        ..color = shape.style.strokeColor.withValues(alpha: shape.style.opacity)
        ..strokeWidth = shape.style.strokeWidth
        ..style = PaintingStyle.stroke;

      final jittered = Rect.fromLTWH(
        rect.left + _jitter(rng, jitter),
        rect.top + _jitter(rng, jitter),
        rect.width + _jitter(rng, jitter),
        rect.height + _jitter(rng, jitter),
      );
      canvas.drawOval(jittered, strokePaint);
    }
  }

  void _paintDiamond(Canvas canvas, DiamondShape shape) {
    final rect = shape.boundingBox;
    final center = rect.center;
    final path = Path()
      ..moveTo(center.dx, rect.top)
      ..lineTo(rect.right, center.dy)
      ..lineTo(center.dx, rect.bottom)
      ..lineTo(rect.left, center.dy)
      ..close();

    if (shape.style.fillStyle != FillStyle.none) {
      final fillPaint = Paint()
        ..color = shape.style.fillColor.withValues(alpha: shape.style.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    final strokePaint = Paint()
      ..color = shape.style.strokeColor.withValues(alpha: shape.style.opacity)
      ..strokeWidth = shape.style.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  void _paintTriangle(Canvas canvas, TriangleShape shape) {
    final verts = shape.vertices;
    final path = Path()
      ..moveTo(verts[0].dx, verts[0].dy)
      ..lineTo(verts[1].dx, verts[1].dy)
      ..lineTo(verts[2].dx, verts[2].dy)
      ..close();

    if (shape.style.fillStyle != FillStyle.none) {
      final fillPaint = Paint()
        ..color = shape.style.fillColor.withValues(alpha: shape.style.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    final strokePaint = Paint()
      ..color = shape.style.strokeColor.withValues(alpha: shape.style.opacity)
      ..strokeWidth = shape.style.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  void _paintLine(Canvas canvas, LineShape shape) {
    final strokePaint = Paint()
      ..color = shape.style.strokeColor.withValues(alpha: shape.style.opacity)
      ..strokeWidth = shape.style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _applyStrokeStyle(strokePaint, shape.style.strokeStyle);
    canvas.drawLine(shape.startPoint, shape.endPoint, strokePaint);
  }

  void _paintArrow(Canvas canvas, ArrowShape shape) {
    final strokePaint = Paint()
      ..color = shape.style.strokeColor.withValues(alpha: shape.style.opacity)
      ..strokeWidth = shape.style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _applyStrokeStyle(strokePaint, shape.style.strokeStyle);
    canvas.drawLine(shape.startPoint, shape.endPoint, strokePaint);

    final angle = atan2(
      shape.endPoint.dy - shape.startPoint.dy,
      shape.endPoint.dx - shape.startPoint.dx,
    );
    final arrowSize = 10.0 + shape.style.strokeWidth * 2;

    if (shape.endArrowhead != ArrowheadStyle.none) {
      _drawArrowhead(canvas, shape.endPoint, angle, arrowSize, shape.style, shape.endArrowhead);
    }
    if (shape.startArrowhead != ArrowheadStyle.none) {
      _drawArrowhead(canvas, shape.startPoint, angle + pi, arrowSize, shape.style, shape.startArrowhead);
    }
  }

  void _drawArrowhead(Canvas canvas, Offset tip, double angle, double size, ShapeStyle style, ArrowheadStyle arrowhead) {
    final paint = Paint()
      ..color = style.strokeColor.withValues(alpha: style.opacity)
      ..strokeWidth = style.strokeWidth
      ..style = PaintingStyle.fill;

    final path = Path();
    const spreadAngle = pi / 6;

    switch (arrowhead) {
      case ArrowheadStyle.triangle:
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(
          tip.dx - size * cos(angle - spreadAngle),
          tip.dy - size * sin(angle - spreadAngle),
        );
        path.lineTo(
          tip.dx - size * cos(angle + spreadAngle),
          tip.dy - size * sin(angle + spreadAngle),
        );
        path.close();
        canvas.drawPath(path, paint);
      case ArrowheadStyle.circle:
        canvas.drawCircle(tip, size / 3, paint);
      case ArrowheadStyle.diamond:
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(
          tip.dx - size / 2 * cos(angle - spreadAngle),
          tip.dy - size / 2 * sin(angle - spreadAngle),
        );
        path.lineTo(
          tip.dx - size * cos(angle),
          tip.dy - size * sin(angle),
        );
        path.lineTo(
          tip.dx - size / 2 * cos(angle + spreadAngle),
          tip.dy - size / 2 * sin(angle + spreadAngle),
        );
        path.close();
        canvas.drawPath(path, paint);
      case ArrowheadStyle.none:
        break;
    }
  }

  void _paintFreehand(Canvas canvas, FreehandShape shape) {
    if (shape.points.isEmpty) return;
    final path = Path();
    path.moveTo(shape.points[0].dx, shape.points[0].dy);
    for (var i = 1; i < shape.points.length; i++) {
      path.lineTo(shape.points[i].dx, shape.points[i].dy);
    }
    if (shape.isClosed) path.close();

    if (shape.style.fillStyle != FillStyle.none && shape.isClosed) {
      final fillPaint = Paint()
        ..color = shape.style.fillColor.withValues(alpha: shape.style.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    final strokePaint = Paint()
      ..color = shape.style.strokeColor.withValues(alpha: shape.style.opacity)
      ..strokeWidth = shape.style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  void _paintText(Canvas canvas, TextShape shape) {
    final textStyle = TextStyle(
      color: shape.style.strokeColor.withValues(alpha: shape.style.opacity),
      fontFamily: shape.fontFamily,
      fontSize: shape.fontSize,
      fontWeight: shape.fontWeight,
    );
    final textSpan = TextSpan(text: shape.text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: shape.textAlign,
    );
    textPainter.layout(maxWidth: shape.boundingBox.width);
    textPainter.paint(canvas, shape.boundingBox.topLeft);
  }

  void _paintImage(Canvas canvas, ImageShape shape) {
    // Image painting is done via the shape's own cached image
    // For now, draw a placeholder
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3);
    canvas.drawRect(shape.boundingBox, paint);
    canvas.drawRect(shape.boundingBox, Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
  }

  void _paintRoughFill(Canvas canvas, Rect rect, ShapeStyle style) {
    final paint = Paint()
      ..color = style.fillColor.withValues(alpha: style.opacity * 0.3)
      ..strokeWidth = 0.5;
    final rng = Random(rect.hashCode);

    switch (style.fillStyle) {
      case FillStyle.crossHatch:
        for (var i = 0; i < rect.width / 10; i++) {
          final x = rect.left + i * 10 + _jitter(rng, 2);
          canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
        }
        for (var i = 0; i < rect.height / 10; i++) {
          final y = rect.top + i * 10 + _jitter(rng, 2);
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
        }
      case FillStyle.diagonalHatch:
        for (var i = -20; i < rect.width + rect.height; i += 10) {
          canvas.drawLine(
            Offset(rect.left + i, rect.top),
            Offset(rect.left + i - rect.height, rect.bottom),
            paint,
          );
        }
      case FillStyle.zigzag:
        final path = Path();
        path.moveTo(rect.left, rect.top);
        var y = rect.top;
        while (y < rect.bottom) {
          path.lineTo(rect.right, y);
          y += 5;
          if (y < rect.bottom) path.lineTo(rect.left, y);
          y += 5;
        }
        canvas.drawPath(path, paint);
      case FillStyle.dotted:
        for (var i = 0; i < 50; i++) {
          final x = rect.left + rng.nextDouble() * rect.width;
          final y = rect.top + rng.nextDouble() * rect.height;
          canvas.drawCircle(Offset(x, y), 1.0, paint);
        }
      case FillStyle.solid:
      case FillStyle.none:
        break;
    }
  }

  void _applyStrokeStyle(Paint paint, StrokeStyle style) {
    switch (style) {
      case StrokeStyle.solid:
        break;
      case StrokeStyle.dashed:
        // Handled via path effects not directly available on Painter
        break;
      case StrokeStyle.dotted:
        break;
    }
  }

  void _paintActiveShape(Canvas canvas) {
    if (activeDrawingStart == null || activeDrawingEnd == null || activeDrawingStyle == null) return;
    if (activeShapeType == null) return;

    final rect = Rect.fromPoints(activeDrawingStart!, activeDrawingEnd!);
    final previewPaint = Paint()
      ..color = activeDrawingStyle!.strokeColor.withValues(alpha: 0.5)
      ..strokeWidth = activeDrawingStyle!.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (activeShapeType!) {
      case ShapeType.rectangle:
        canvas.drawRect(rect, previewPaint);
      case ShapeType.ellipse:
        canvas.drawOval(rect, previewPaint);
      case ShapeType.diamond:
        final center = rect.center;
        final diamondPath = Path()
          ..moveTo(center.dx, rect.top)
          ..lineTo(rect.right, center.dy)
          ..lineTo(center.dx, rect.bottom)
          ..lineTo(rect.left, center.dy)
          ..close();
        canvas.drawPath(diamondPath, previewPaint);
      case ShapeType.line:
        canvas.drawLine(activeDrawingStart!, activeDrawingEnd!, previewPaint);
      case ShapeType.arrow:
        canvas.drawLine(activeDrawingStart!, activeDrawingEnd!, previewPaint);
      default:
        canvas.drawRect(rect, previewPaint);
    }
  }

  void _paintSelectionOverlay(Canvas canvas, Size screenSize) {
    final selectedShapes = shapes.where((s) => selection.isSelected(s.id)).toList();
    if (selectedShapes.isEmpty) return;

    for (final shape in selectedShapes) {
      final screenRect = transform.worldToScreenRect(shape.rotatedBoundingBox);
      final paint = Paint()
        ..color = const Color(0xFF4A90D9)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(screenRect, paint);

      if (selection.isSingle) {
        final handlePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final handleBorder = Paint()
          ..color = const Color(0xFF4A90D9)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        final handleSize = CanvasConstants.handleSize;

        final handles = [
          screenRect.topLeft,
          Offset(screenRect.center.dx, screenRect.top),
          screenRect.topRight,
          Offset(screenRect.left, screenRect.center.dy),
          Offset(screenRect.right, screenRect.center.dy),
          screenRect.bottomLeft,
          Offset(screenRect.center.dx, screenRect.bottom),
          screenRect.bottomRight,
        ];

        for (final pos in handles) {
          final handleRect = Rect.fromCenter(center: pos, width: handleSize, height: handleSize);
          canvas.drawRect(handleRect, handlePaint);
          canvas.drawRect(handleRect, handleBorder);
        }

        final rotationPos = Offset(screenRect.center.dx, screenRect.top - 24);
        canvas.drawCircle(rotationPos, CanvasConstants.rotationHandleSize / 2, handlePaint);
        canvas.drawCircle(rotationPos, CanvasConstants.rotationHandleSize / 2, handleBorder);
      }
    }
  }

  void _paintMarquee(Canvas canvas, Rect marqueeRect) {
    final fillPaint = Paint()
      ..color = const Color(0xFF4A90D9).withValues(alpha: 0.1);
    final borderPaint = Paint()
      ..color = const Color(0xFF4A90D9)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(marqueeRect, fillPaint);
    canvas.drawRect(marqueeRect, borderPaint);
  }

  double _jitter(Random rng, double amplitude) {
    return (rng.nextDouble() - 0.5) * 2 * amplitude;
  }

  @override
  bool shouldRepaint(covariant CanvasEngine oldDelegate) {
    return oldDelegate.shapes != shapes ||
        oldDelegate.transform != transform ||
        oldDelegate.selection != selection ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.isDark != isDark ||
        oldDelegate.activeDrawingStart != activeDrawingStart ||
        oldDelegate.activeDrawingEnd != activeDrawingEnd ||
        oldDelegate.activeDrawingStyle != activeDrawingStyle ||
        oldDelegate.activeShapeType != activeShapeType ||
        oldDelegate.pictureCache != pictureCache;
  }
}
