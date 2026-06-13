import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_summary.dart';

final projectListProvider = StateNotifierProvider<ProjectListNotifier, List<ProjectSummary>>(
  (ref) => ProjectListNotifier(),
);

class ProjectListNotifier extends StateNotifier<List<ProjectSummary>> {
  ProjectListNotifier() : super([]);

  void load(List<ProjectSummary> projects) {
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
