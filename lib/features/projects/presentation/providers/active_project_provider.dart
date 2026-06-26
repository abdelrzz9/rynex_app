import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/project_storage_service.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_summary.dart';
import 'project_list_provider.dart';

final activeProjectProvider = StateNotifierProvider<ActiveProjectNotifier, Project?>(
  (ref) {
    final storage = ref.read(projectStorageServiceProvider);
    return ActiveProjectNotifier(storage, ref);
  },
);

final saveErrorProvider = StateProvider<String?>((ref) => null);

class ActiveProjectNotifier extends StateNotifier<Project?> {
  final ProjectStorageService _storage;
  final Ref _ref;
  Timer? _saveTimer;

  ActiveProjectNotifier(this._storage, this._ref) : super(null);

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
    _ref.read(projectListProvider.notifier).update(ProjectSummary(
      id: state!.id,
      name: state!.name,
      createdAt: state!.createdAt,
      updatedAt: state!.updatedAt,
      thumbnailPath: state!.thumbnailPath,
      shapeCount: state!.shapes.length,
    ));
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
      _ref.read(saveErrorProvider.notifier).state = null;
    } on Object catch (e) {
      debugPrint('Failed to save project: $e');
      _ref.read(saveErrorProvider.notifier).state = 'Failed to save project. Check available storage.';
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_save().then((_) {}).catchError((_) {}));
    super.dispose();
  }
}
