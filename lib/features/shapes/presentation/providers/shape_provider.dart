import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../domain/entities/shape_entity.dart';

final shapeListProvider =
    StateNotifierProvider<ShapeListNotifier, List<ShapeEntity>>(
  (ref) => ShapeListNotifier(),
);

class ShapeListNotifier extends StateNotifier<List<ShapeEntity>> {
  ShapeListNotifier() : super([]);

  void addShape(ShapeEntity shape) {
    state = [...state, shape];
  }

  void removeShape(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void removeShapes(List<String> ids) {
    final idSet = ids.toSet();
    state = state.where((s) => !idSet.contains(s.id)).toList();
  }

  void updateShape(String id, ShapeEntity updated) {
    state = state.map((s) => s.id == id ? updated : s).toList();
  }

  void updateShapes(Iterable<ShapeEntity> shapes) {
    final map = {for (final s in shapes) s.id: s};
    state = state.map((s) => map[s.id] ?? s).toList();
  }

  void reorderShape(String id, int newOrder) {
    state = state.map((s) {
      if (s.id != id) return s;
      return s.copyWith(layer: s.layer.copyWith(order: newOrder));
    }).toList();
  }

  void bringToFront(String id) {
    final maxOrder = state.map((s) => s.layer.order).reduce(
      (a, b) => a > b ? a : b,
    );
    reorderShape(id, maxOrder + 1);
  }

  void sendToBack(String id) {
    final minOrder = state.map((s) => s.layer.order).reduce(
      (a, b) => a < b ? a : b,
    );
    reorderShape(id, minOrder - 1);
  }

  void moveUp(String id) {
    final shape = state.firstWhereOrNull((s) => s.id == id);
    if (shape == null) return;
    final above = state.where(
      (s) => s.layer.order > shape.layer.order,
    );
    if (above.isEmpty) return;
    final target = above.reduce(
      (a, b) => a.layer.order < b.layer.order ? a : b,
    );
    final temp = shape.layer.order;
    state = state.map((s) {
      if (s.id == id) return s.copyWith(layer: s.layer.copyWith(order: target.layer.order));
      if (s.id == target.id) return s.copyWith(layer: s.layer.copyWith(order: temp));
      return s;
    }).toList();
  }

  void moveDown(String id) {
    final shape = state.firstWhereOrNull((s) => s.id == id);
    if (shape == null) return;
    final below = state.where(
      (s) => s.layer.order < shape.layer.order,
    );
    if (below.isEmpty) return;
    final target = below.reduce(
      (a, b) => a.layer.order > b.layer.order ? a : b,
    );
    final temp = shape.layer.order;
    state = state.map((s) {
      if (s.id == id) return s.copyWith(layer: s.layer.copyWith(order: target.layer.order));
      if (s.id == target.id) return s.copyWith(layer: s.layer.copyWith(order: temp));
      return s;
    }).toList();
  }

  void clearAll() {
    state = [];
  }

  void loadShapes(List<ShapeEntity> shapes) {
    state = shapes;
  }

  List<ShapeEntity> get sortedByLayer {
    return [...state]..sort((a, b) => a.layer.order.compareTo(b.layer.order));
  }
}
