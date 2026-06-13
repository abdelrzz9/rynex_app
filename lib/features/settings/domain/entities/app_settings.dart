import 'package:equatable/equatable.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../shapes/domain/entities/shape.dart';

class AppSettings extends Equatable {
  final bool isDarkMode;
  final DrawingTool defaultTool;
  final ShapeStyle defaultStyle;
  final String? lastOpenedProjectId;
  final bool showGrid;
  final bool snapToGrid;

  const AppSettings({
    this.isDarkMode = false,
    this.defaultTool = DrawingTool.select,
    this.defaultStyle = const ShapeStyle(),
    this.lastOpenedProjectId,
    this.showGrid = true,
    this.snapToGrid = false,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    DrawingTool? defaultTool,
    ShapeStyle? defaultStyle,
    String? lastOpenedProjectId,
    bool? showGrid,
    bool? snapToGrid,
    bool clearLastProject = false,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultTool: defaultTool ?? this.defaultTool,
      defaultStyle: defaultStyle ?? this.defaultStyle,
      lastOpenedProjectId: clearLastProject ? null : (lastOpenedProjectId ?? this.lastOpenedProjectId),
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
    );
  }

  @override
  List<Object?> get props => [
        isDarkMode,
        defaultTool,
        defaultStyle,
        lastOpenedProjectId,
        showGrid,
        snapToGrid,
      ];
}
