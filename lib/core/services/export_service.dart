import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/shapes/domain/entities/shape_entity.dart';

class ExportService {
  Future<void> exportPng(List<ShapeEntity> shapes, Rect contentBounds, GlobalKey repaintKey) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/rynex_export_$timestamp.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    _shareFile(file);
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

    _shareFile(file);
  }

  Future<void> _shareFile(File file) async {
    // On desktop/mobile, use share dialog
    // For now, save to downloads directory
    try {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        await file.copy('${downloads.path}/${file.path.split('/').last}');
      }
    } catch (_) {}

    // Print path for debugging
    debugPrint('Exported to: ${file.path}');
  }

  static Rect calculateContentBounds(List<ShapeEntity> shapes) {
    if (shapes.isEmpty) return Rect.zero;
    return shapes.map((s) => s.rotatedBoundingBox).reduce(
      (a, b) => a.expandToInclude(b),
    );
  }
}
