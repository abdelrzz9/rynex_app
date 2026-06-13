import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/project_storage_service.dart';
import '../../domain/entities/project_summary.dart';

final projectListProvider = StateNotifierProvider<ProjectListNotifier, List<ProjectSummary>>(
  (ref) {
    final storage = ref.read(projectStorageServiceProvider);
    return ProjectListNotifier(storage);
  },
);

class ProjectListNotifier extends StateNotifier<List<ProjectSummary>> {
  final ProjectStorageService _storage;

  ProjectListNotifier(this._storage) : super([]);

  Future<void> loadProjects() async {
    final projects = await _storage.listProjects();
    state = projects;
  }

  void add(ProjectSummary project) {
    state = [...state, project];
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void update(ProjectSummary project) {
    state = state.map((p) => p.id == project.id ? project : p).toList();
  }
}
