import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/settings_storage_service.dart';
import '../../../shapes/domain/entities/shape.dart';
import '../../domain/entities/app_settings.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) {
    final storage = ref.read(settingsStorageServiceProvider);
    return SettingsNotifier(storage);
  },
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsStorageService _storage;

  SettingsNotifier(this._storage) : super(const AppSettings());

  Future<void> loadSettings() async {
    state = await _storage.load();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void toggleDarkMode() {
    final newMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : state.themeMode == ThemeMode.light
            ? ThemeMode.system
            : ThemeMode.dark;
    state = state.copyWith(themeMode: newMode);
    _save();
  }

  void setDarkMode(bool value) {
    state = state.copyWith(themeMode: value ? ThemeMode.dark : ThemeMode.light);
    _save();
  }

  void setDefaultTool(DrawingTool tool) {
    state = state.copyWith(defaultTool: tool);
    _save();
  }

  void setDefaultStyle(ShapeStyle style) {
    state = state.copyWith(defaultStyle: style);
    _save();
  }

  void setLastOpenedProject(String projectId) {
    state = state.copyWith(lastOpenedProjectId: projectId);
    _save();
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
    _save();
  }

  void toggleSnap() {
    state = state.copyWith(snapToGrid: !state.snapToGrid);
    _save();
  }

  void setCanvasSize(double width, double height, String label) {
    state = state.copyWith(canvasWidth: width, canvasHeight: height, canvasSizeLabel: label);
    _save();
  }

  set settings(AppSettings value) {
    state = value;
  }

  Future<void> _save() async {
    try {
      await _storage.save(state);
    } on Object catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }
}
