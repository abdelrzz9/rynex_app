import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../shapes/domain/entities/shape.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final DrawingTool defaultTool;
  final ShapeStyle defaultStyle;
  final String? lastOpenedProjectId;
  final bool showGrid;
  final bool snapToGrid;
  final double canvasWidth;
  final double canvasHeight;
  final String canvasSizeLabel;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultTool = DrawingTool.select,
    this.defaultStyle = const ShapeStyle(),
    this.lastOpenedProjectId,
    this.showGrid = true,
    this.snapToGrid = false,
    this.canvasWidth = 800,
    this.canvasHeight = 1100,
    this.canvasSizeLabel = 'A4',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    DrawingTool? defaultTool,
    ShapeStyle? defaultStyle,
    String? lastOpenedProjectId,
    bool? showGrid,
    bool? snapToGrid,
    double? canvasWidth,
    double? canvasHeight,
    String? canvasSizeLabel,
    bool clearLastProject = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultTool: defaultTool ?? this.defaultTool,
      defaultStyle: defaultStyle ?? this.defaultStyle,
      lastOpenedProjectId: clearLastProject ? null : (lastOpenedProjectId ?? this.lastOpenedProjectId),
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      canvasSizeLabel: canvasSizeLabel ?? this.canvasSizeLabel,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        defaultTool,
        defaultStyle,
        lastOpenedProjectId,
        showGrid,
        snapToGrid,
        canvasWidth,
        canvasHeight,
        canvasSizeLabel,
      ];
}

class PresetCanvasSize {
  final String label;
  final double width;
  final double height;

  const PresetCanvasSize(this.label, this.width, this.height);

  static const List<PresetCanvasSize> presets = [
    PresetCanvasSize('A4', 800, 1100),
    PresetCanvasSize('A3', 1100, 1500),
    PresetCanvasSize('Square', 800, 800),
    PresetCanvasSize('Story', 540, 960),
    PresetCanvasSize('Instagram', 600, 600),
    PresetCanvasSize('HD', 1280, 720),
    PresetCanvasSize('4K', 1920, 1080),
  ];
}
