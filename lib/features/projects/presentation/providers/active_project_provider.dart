import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../../core/services/project_storage_service.dart';
import '../../../../core/di/injection_container.dart';

final activeProjectProvider = StateNotifierProvider<ActiveProjectNotifier, Project?>(
  (ref) {
    final storage = ref.read(projectStorageServiceProvider);
    return ActiveProjectNotifier(storage, ref);
  },
);

class ActiveProjectNotifier extends StateNotifier<Project?> {
  final ProjectStorageService _storage;
  Timer? _saveTimer;

  ActiveProjectNotifier(this._storage, Ref ref) : super(null);

  Future<void> open(Project project) async {
    state = project;
    _scheduleSave();
  }

  Future<Project?> load(String id) async {
    state = await _storage.loadProject(id);
    return state;
  }

  Future<void> close() async {
    await _save();
    state = null;
  }

  Future<void> saveNow() async {
    await _save();
  }

  void updateName(String name) {
    if (state == null) return;
    state = state!.copyWith(name: name, updatedAt: DateTime.now());
    _scheduleSave();
  }

  void updateShapes(List<ShapeEntity> shapes) {
    if (state == null) return;
    state = state!.copyWith(shapes: shapes, updatedAt: DateTime.now());
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    if (state == null) return;
    try {
      await _storage.saveProject(state!);
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save();
    super.dispose();
  }
}
