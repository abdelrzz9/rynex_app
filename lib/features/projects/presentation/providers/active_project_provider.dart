import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../../shapes/domain/entities/shape_entity.dart';

final activeProjectProvider = StateNotifierProvider<ActiveProjectNotifier, Project?>(
  (ref) => ActiveProjectNotifier(),
);

class ActiveProjectNotifier extends StateNotifier<Project?> {
  ActiveProjectNotifier() : super(null);

  void open(Project project) {
    state = project;
  }

  void close() {
    state = null;
  }

  void updateName(String name) {
    if (state == null) return;
    state = state!.copyWith(name: name, updatedAt: DateTime.now());
  }

  void updateShapes(List<ShapeEntity> shapes) {
    if (state == null) return;
    state = state!.copyWith(shapes: shapes, updatedAt: DateTime.now());
  }
}
