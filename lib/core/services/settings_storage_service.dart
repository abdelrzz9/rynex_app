import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../core/constants/tool_constants.dart';
import '../../features/shapes/domain/entities/shape.dart';
import '../../features/shapes/domain/value_objects/stroke_style.dart';
import '../../features/shapes/domain/value_objects/fill_style.dart';
import '../../features/shapes/domain/value_objects/roughness.dart';

class SettingsStorageService {
  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/rynex');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _file = File('${dir.path}/settings.json');
    return _file!;
  }

  Future<void> save(AppSettings settings) async {
    final file = await _getFile();
    final data = {
      'isDarkMode': settings.isDarkMode,
      'defaultTool': settings.defaultTool.name,
      'defaultStyle': {
        'strokeColor': settings.defaultStyle.strokeColor.toARGB32(),
        'strokeWidth': settings.defaultStyle.strokeWidth,
        'strokeStyle': settings.defaultStyle.strokeStyle.name,
        'fillColor': settings.defaultStyle.fillColor.toARGB32(),
        'fillStyle': settings.defaultStyle.fillStyle.name,
        'roughness': settings.defaultStyle.roughness.name,
        'opacity': settings.defaultStyle.opacity,
      },
      'lastOpenedProjectId': settings.lastOpenedProjectId,
      'showGrid': settings.showGrid,
      'snapToGrid': settings.snapToGrid,
    };
    await file.writeAsString(jsonEncode(data));
  }

  Future<AppSettings> load() async {
    final file = await _getFile();
    if (!await file.exists()) return const AppSettings();
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AppSettings(
        isDarkMode: data['isDarkMode'] as bool? ?? false,
        defaultTool: DrawingTool.values.firstWhere(
          (t) => t.name == data['defaultTool'],
          orElse: () => DrawingTool.select,
        ),
        defaultStyle: _parseStyle(data['defaultStyle'] as Map<String, dynamic>?),
        lastOpenedProjectId: data['lastOpenedProjectId'] as String?,
        showGrid: data['showGrid'] as bool? ?? true,
        snapToGrid: data['snapToGrid'] as bool? ?? false,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  ShapeStyle _parseStyle(Map<String, dynamic>? data) {
    if (data == null) return const ShapeStyle();
    return ShapeStyle(
      strokeColor: Color(data['strokeColor'] as int? ?? Colors.black.toARGB32()),
      strokeWidth: (data['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeStyle: StrokeStyle.values.firstWhere(
        (s) => s.name == data['strokeStyle'],
        orElse: () => StrokeStyle.solid,
      ),
      fillColor: Color(data['fillColor'] as int? ?? Colors.transparent.toARGB32()),
      fillStyle: FillStyle.values.firstWhere(
        (s) => s.name == data['fillStyle'],
        orElse: () => FillStyle.none,
      ),
      roughness: Roughness.values.firstWhere(
        (r) => r.name == data['roughness'],
        orElse: () => Roughness.none,
      ),
      opacity: (data['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
