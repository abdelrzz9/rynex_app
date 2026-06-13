import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum HandleType {
  topLeft,
  topCenter,
  topRight,
  midLeft,
  midRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  rotation,
}

class SelectionState extends Equatable {
  final Set<String> selectedIds;
  final Rect? marqueeRect;
  final HandleType? activeHandle;
  final Offset? dragStart;
  final String? lastSelectedId;

  const SelectionState({
    this.selectedIds = const {},
    this.marqueeRect,
    this.activeHandle,
    this.dragStart,
    this.lastSelectedId,
  });

  bool get isEmpty => selectedIds.isEmpty;
  bool get isNotEmpty => selectedIds.isNotEmpty;
  bool get isSingle => selectedIds.length == 1;
  bool get isMultiple => selectedIds.length > 1;
  bool get hasMarquee => marqueeRect != null;
  bool get hasActiveHandle => activeHandle != null;

  bool isSelected(String id) => selectedIds.contains(id);

  SelectionState copyWith({
    Set<String>? selectedIds,
    Rect? marqueeRect,
    HandleType? activeHandle,
    Offset? dragStart,
    String? lastSelectedId,
    bool clearMarquee = false,
    bool clearActiveHandle = false,
    bool clearDragStart = false,
  }) {
    return SelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      marqueeRect: clearMarquee ? null : (marqueeRect ?? this.marqueeRect),
      activeHandle: clearActiveHandle ? null : (activeHandle ?? this.activeHandle),
      dragStart: clearDragStart ? null : (dragStart ?? this.dragStart),
      lastSelectedId: lastSelectedId ?? this.lastSelectedId,
    );
  }

  @override
  List<Object?> get props => [selectedIds, marqueeRect, activeHandle, dragStart, lastSelectedId];
}
