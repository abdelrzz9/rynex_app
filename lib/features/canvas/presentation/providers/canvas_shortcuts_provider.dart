import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import 'canvas_provider.dart';

final keyboardHandlerProvider = Provider<KeyboardHandler>((ref) {
  return KeyboardHandler(ref);
});

class KeyboardHandler {
  final Ref _ref;

  KeyboardHandler(this._ref);

  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final logical = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    if (isCtrl && logical == LogicalKeyboardKey.keyZ) {
      _ref.read(historyProvider.notifier).undo();
      return true;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyY) {
      _ref.read(historyProvider.notifier).redo();
      return true;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyA) {
      _selectAll();
      return true;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyD) {
      _duplicateSelected();
      return true;
    }
    if (logical == LogicalKeyboardKey.delete ||
        logical == LogicalKeyboardKey.backspace) {
      _deleteSelected();
      return true;
    }
    if (isCtrl && isShift && logical == LogicalKeyboardKey.keyG) {
      _ref.read(canvasProvider.notifier).toggleGrid();
      return true;
    }
    if (isCtrl && isShift && logical == LogicalKeyboardKey.keyE) {
      _ref.read(canvasProvider.notifier).toggleSnap();
      return true;
    }
    if (isCtrl && logical == LogicalKeyboardKey.equal) {
      _ref.read(canvasProvider.notifier).zoomIn(Offset.zero);
      return true;
    }
    if (isCtrl && logical == LogicalKeyboardKey.minus) {
      _ref.read(canvasProvider.notifier).zoomOut(Offset.zero);
      return true;
    }
    if (isCtrl && logical == LogicalKeyboardKey.digit0) {
      _ref.read(canvasProvider.notifier).resetViewport();
      return true;
    }

    return false;
  }

  void _selectAll() {
    final shapes = _ref.read(shapeListProvider);
    final ids = shapes.map((s) => s.id).toSet();
    _ref.read(selectionProvider.notifier).selectMultiple(ids);
  }

  void _deleteSelected() {
    final selection = _ref.read(selectionProvider);
    final shapes = _ref.read(shapeListProvider);
    final toRemove = shapes.where((s) => selection.isSelected(s.id)).toList();
    if (toRemove.isEmpty) return;
    _ref.read(historyProvider.notifier).executeDelete(toRemove);
  }

  void _duplicateSelected() {
    final selection = _ref.read(selectionProvider);
    final shapes = _ref.read(shapeListProvider);
    final toDup = shapes.where((s) => selection.isSelected(s.id)).toList();
    if (toDup.isEmpty) return;
    _ref.read(historyProvider.notifier).executeDuplicate(toDup);
  }
}
