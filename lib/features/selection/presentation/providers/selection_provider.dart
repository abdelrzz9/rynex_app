import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/selection_state.dart';

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>(
  (ref) => SelectionNotifier(),
);

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(const SelectionState());

  void select(String id) {
    state = state.copyWith(
      selectedIds: {id},
      lastSelectedId: id,
      clearMarquee: true,
    );
  }

  void toggleSelect(String id) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(
      selectedIds: ids,
      lastSelectedId: id,
      clearMarquee: true,
    );
  }

  void selectMultiple(Set<String> ids) {
    state = state.copyWith(
      selectedIds: ids,
      clearMarquee: true,
    );
  }

  void deselectAll() {
    state = const SelectionState();
  }

  void deselect(String id) {
    final ids = Set<String>.from(state.selectedIds)..remove(id);
    state = state.copyWith(selectedIds: ids, clearMarquee: true);
  }

  void startMarquee(Offset start) {
    state = state.copyWith(
      marqueeRect: Rect.fromPoints(start, start),
      clearActiveHandle: true,
    );
  }

  void updateMarquee(Offset current) {
    if (!state.hasMarquee) return;
    final rect = Rect.fromPoints(state.marqueeRect!.topLeft, current);
    state = state.copyWith(marqueeRect: rect);
  }

  void endMarquee(List<String> shapeIds) {
    state = state.copyWith(
      selectedIds: shapeIds.toSet(),
      clearMarquee: true,
      lastSelectedId: shapeIds.isNotEmpty ? shapeIds.last : null,
    );
  }

  void setActiveHandle(HandleType handle, Offset dragStart) {
    state = state.copyWith(
      activeHandle: handle,
      dragStart: dragStart,
    );
  }

  void clearActiveHandle() {
    state = state.copyWith(clearActiveHandle: true, clearDragStart: true);
  }

  void updateDragStart(Offset position) {
    state = state.copyWith(dragStart: position);
  }

  bool isSelected(String id) => state.isSelected(id);
}
