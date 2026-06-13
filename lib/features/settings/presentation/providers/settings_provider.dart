import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_settings.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../shapes/domain/entities/shape.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void setDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
  }

  void setDefaultTool(DrawingTool tool) {
    state = state.copyWith(defaultTool: tool);
  }

  void setDefaultStyle(ShapeStyle style) {
    state = state.copyWith(defaultStyle: style);
  }

  void setLastOpenedProject(String projectId) {
    state = state.copyWith(lastOpenedProjectId: projectId);
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  void toggleSnap() {
    state = state.copyWith(snapToGrid: !state.snapToGrid);
  }

  void load(AppSettings settings) {
    state = settings;
  }
}
