import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/project_storage_service.dart';
import '../services/settings_storage_service.dart';

final projectStorageServiceProvider = Provider<ProjectStorageService>((ref) {
  return ProjectStorageService();
});

final settingsStorageServiceProvider = Provider<SettingsStorageService>((ref) {
  return SettingsStorageService();
});

final themeModeProvider = StateProvider<bool>((ref) => false);
