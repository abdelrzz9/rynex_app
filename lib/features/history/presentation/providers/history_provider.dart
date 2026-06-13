import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/domain/entities/shape_factory.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../../domain/commands/add_shape_command.dart';
import '../../domain/commands/command.dart';
import '../../domain/commands/composite_command.dart';
import '../../domain/commands/modify_shape_command.dart';
import '../../domain/commands/remove_shape_command.dart';
import '../../domain/entities/history_state.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier(ref),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super(const HistoryState());

  void execute(Command command) {
    command.execute();
    final newUndo = [...state.undoStack, command];
    if (newUndo.length > state.maxSize) {
      newUndo.removeAt(0);
    }
    state = state.copyWith(
      undoStack: newUndo,
      redoStack: [],
    );
  }

  void executeAdd(ShapeEntity shape) {
    final command = AddShapeCommand(
      shape: shape,
      onAdd: (s) => _ref.read(shapeListProvider.notifier).addShape(s),
      onRemove: (id) => _ref.read(shapeListProvider.notifier).removeShape(id),
    );
    execute(command);
  }

  void executeDelete(List<ShapeEntity> shapes) {
    if (shapes.length == 1) {
      final shape = shapes.first;
      final command = RemoveShapeCommand(
        shape: shape,
        onAdd: (s) => _ref.read(shapeListProvider.notifier).addShape(s),
        onRemove: (id) => _ref.read(shapeListProvider.notifier).removeShape(id),
        index: _ref.read(shapeListProvider).indexOf(shape),
      );
      execute(command);
    } else {
      final commands = shapes.map((shape) => RemoveShapeCommand(
        shape: shape,
        onAdd: (s) => _ref.read(shapeListProvider.notifier).addShape(s),
        onRemove: (id) => _ref.read(shapeListProvider.notifier).removeShape(id),
        index: _ref.read(shapeListProvider).indexOf(shape),
      ) as Command).toList();
      execute(CompositeCommand(commands));
    }
    _ref.read(selectionProvider.notifier).deselectAll();
  }

  void executeDuplicate(List<ShapeEntity> shapes) {
    final commands = <Command>[];
    for (final shape in shapes) {
      const offset = Offset(20, 20);
      final newBox = shape.boundingBox.translate(offset.dx, offset.dy);
      final json = Map<String, dynamic>.from(shape.toJson());
      json['id'] = UuidGenerator.generate();
      json['x'] = newBox.left;
      json['y'] = newBox.top;
      final dup = ShapeFactory.fromJson(json);
      commands.add(AddShapeCommand(
        shape: dup,
        onAdd: (s) => _ref.read(shapeListProvider.notifier).addShape(s),
        onRemove: (id) => _ref.read(shapeListProvider.notifier).removeShape(id),
      ));
    }
    execute(CompositeCommand(commands));
  }

  void executeModify(String shapeId, ShapeEntity oldState, ShapeEntity newState) {
    final command = ModifyShapeCommand(
      shapeId: shapeId,
      oldState: oldState,
      newState: newState,
      onUpdate: (id, s) => _ref.read(shapeListProvider.notifier).updateShape(id, s),
    );
    execute(command);
  }

  void undo() {
    if (!state.canUndo) return;
    final command = state.undoStack.last;
    command.undo();
    state = state.copyWith(
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
      redoStack: [...state.redoStack, command],
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final command = state.redoStack.last;
    command.execute();
    state = state.copyWith(
      undoStack: [...state.undoStack, command],
      redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
    );
  }

  void clear() {
    state = const HistoryState();
  }
}

final canUndoProvider = Provider<bool>((ref) {
  return ref.watch(historyProvider.select((s) => s.canUndo));
});

final canRedoProvider = Provider<bool>((ref) {
  return ref.watch(historyProvider.select((s) => s.canRedo));
});
