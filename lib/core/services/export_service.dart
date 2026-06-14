import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/canvas/domain/entities/canvas_transform.dart';
import '../../features/shapes/domain/entities/shape_entity.dart';

class ExportService {
  Future<void> exportPng(
    List<ShapeEntity> shapes,
    Rect contentBounds,
    GlobalKey repaintKey, {
    double canvasWidth = 800,
    double canvasHeight = 1100,
    CanvasTransform? transform,
  }) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final imageBytes = await _cropToCanvas(image, canvasWidth, canvasHeight, transform);
    if (imageBytes == null) return;

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/rynex_export_$timestamp.png');
    await file.writeAsBytes(imageBytes);

    await _shareFile(file);
  }

  Future<void> exportJpg(
    List<ShapeEntity> shapes,
    Rect contentBounds,
    GlobalKey repaintKey, {
    double canvasWidth = 800,
    double canvasHeight = 1100,
    CanvasTransform? transform,
  }) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final imageBytes = await _cropToCanvas(image, canvasWidth, canvasHeight, transform);
    if (imageBytes == null) return;

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/rynex_export_$timestamp.jpg');

    await file.writeAsBytes(imageBytes);

    await _shareFile(file);
  }

  Future<void> exportPdf(
    List<ShapeEntity> shapes,
    Rect contentBounds,
    GlobalKey repaintKey, {
    double canvasWidth = 800,
    double canvasHeight = 1100,
    CanvasTransform? transform,
  }) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final imageBytes = await _cropToCanvas(image, canvasWidth, canvasHeight, transform);
    if (imageBytes == null) return;

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/rynex_export_$timestamp.pdf');

    await file.writeAsBytes(imageBytes);

    await _shareFile(file);
  }

  Future<Uint8List?> _cropToCanvas(
    ui.Image image,
    double canvasWidth,
    double canvasHeight,
    CanvasTransform? transform,
  ) async {
    if (transform == null) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }

    final pixelRatio = image.width / (transform.pan.dx * 2 + image.width / (transform.zoom * 2));
    final screenCanvasTopLeft = transform.worldToScreen(Offset.zero);
    final screenCanvasBottomRight = transform.worldToScreen(Offset(canvasWidth, canvasHeight));
    final canvasScreenRect = Rect.fromLTRB(
      screenCanvasTopLeft.dx * pixelRatio,
      screenCanvasTopLeft.dy * pixelRatio,
      screenCanvasBottomRight.dx * pixelRatio,
      screenCanvasBottomRight.dy * pixelRatio,
    );

    if (canvasScreenRect.isEmpty || canvasScreenRect.width <= 0 || canvasScreenRect.height <= 0) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final srcRect = Rect.fromLTWH(
      canvasScreenRect.left.clamp(0, image.width.toDouble()),
      canvasScreenRect.top.clamp(0, image.height.toDouble()),
      canvasScreenRect.width.clamp(1, image.width.toDouble()),
      canvasScreenRect.height.clamp(1, image.height.toDouble()),
    );
    canvas.drawImageRect(image, srcRect, Rect.fromLTWH(0, 0, srcRect.width, srcRect.height), Paint());
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(srcRect.width.toInt(), srcRect.height.toInt());
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> exportJson(List<ShapeEntity> shapes) async {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'shapes': shapes.map((s) => s.toJson()).toList(),
    };

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/rynex_export_$timestamp.rynex');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

    await _shareFile(file);
  }

  Future<void> _shareFile(File file) async {
    try {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        await file.copy('${downloads.path}/${file.path.split('/').last}');
      }
    } on Exception catch (_) {}

    debugPrint('Exported to: ${file.path}');
  }

  static Rect calculateContentBounds(List<ShapeEntity> shapes) {
    if (shapes.isEmpty) return Rect.zero;
    return shapes.map((s) => s.rotatedBoundingBox).reduce(
      (a, b) => a.expandToInclude(b),
    );
  }
}
