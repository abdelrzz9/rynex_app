import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../../domain/entities/layer.dart';

final activeLayerIdProvider = StateProvider<int>((ref) => 0);

final layerListProvider = StateNotifierProvider<LayerListNotifier, List<LayerEntity>>(
  (ref) => LayerListNotifier(ref),
);

class LayerListNotifier extends StateNotifier<List<LayerEntity>> {
  final Ref _ref;

  LayerListNotifier(this._ref) : super([const LayerEntity(id: 0, name: 'Layer 1', order: 0)]);

  void addLayer(String name) {
    final order = state.isEmpty ? 0 : state.map((l) => l.order).reduce((a, b) => a > b ? a : b) + 1;
    final id = state.isEmpty ? 0 : state.map((l) => l.id).reduce((a, b) => a > b ? a : b) + 1;
    state = [...state, LayerEntity(id: id, name: name, order: order)];
  }

  void removeLayer(int id) {
    if (state.length <= 1) return;
    final layer = state.firstWhere((l) => l.id == id);
    final shapes = _ref.read(shapeListProvider);
    final removedIds = shapes.where((s) => s.layer.order == layer.order).map((s) => s.id).toList();
    if (removedIds.isNotEmpty) {
      _ref.read(shapeListProvider.notifier).removeShapes(removedIds);
    }
    state = state.where((l) => l.id != id).toList();
  }

  void toggleVisibility(int id) {
    state = state.map((l) {
      if (l.id != id) return l;
      final layer = l.copyWith(isVisible: !l.isVisible);
      _syncShapesToLayer(layer);
      return layer;
    }).toList();
  }

  void toggleLock(int id) {
    state = state.map((l) {
      if (l.id != id) return l;
      final layer = l.copyWith(isLocked: !l.isLocked);
      _syncShapesToLayer(layer);
      return layer;
    }).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(adjusted, item);
    state = list.asMap().entries.map((e) => e.value.copyWith(order: e.key)).toList();
    _syncAllShapes();
  }

  void rename(int id, String name) {
    state = state.map((l) => l.id == id ? l.copyWith(name: name) : l).toList();
  }

  void loadFromShapes(List<ShapeEntity> shapes) {
    final orders = shapes.map((s) => s.layer.order).toSet().toList()..sort();
    if (orders.isEmpty) {
      state = [const LayerEntity(id: 0, name: 'Layer 1', order: 0)];
      return;
    }
    final layers = orders.map((o) {
      final shape = shapes.firstWhere((s) => s.layer.order == o);
      return LayerEntity(
        id: o,
        name: shape.layer.name ?? 'Layer ${o + 1}',
        order: o,
        isVisible: shape.isVisible,
        isLocked: shape.isLocked,
      );
    }).toList();
    state = layers;
  }

  void _syncShapesToLayer(LayerEntity layer) {
    final shapes = _ref.read(shapeListProvider);
    for (final shape in shapes) {
      if (shape.layer.order == layer.order) {
        _ref.read(shapeListProvider.notifier).updateShape(shape.id,
          shape.copyWith(
            layer: shape.layer.copyWith(
              isVisible: layer.isVisible,
              isLocked: layer.isLocked,
            ),
          ),
        );
      }
    }
  }

  void _syncAllShapes() {
    for (final layer in state) {
      _syncShapesToLayer(layer);
    }
  }
}
