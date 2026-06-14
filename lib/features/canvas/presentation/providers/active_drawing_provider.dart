import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shapes/domain/entities/shape.dart';
import '../../../shapes/domain/entities/shape_type.dart';

final activeDrawingProvider = StateProvider<ActiveDrawingState>((ref) {
  return const ActiveDrawingState();
});

class ActiveDrawingState {
  final Offset? start;
  final Offset? end;
  final ShapeStyle? style;
  final ShapeType? type;
  final List<Offset> points;

  const ActiveDrawingState({
    this.start,
    this.end,
    this.style,
    this.type,
    this.points = const [],
  });

  ActiveDrawingState copyWith({
    Offset? start,
    Offset? end,
    ShapeStyle? style,
    ShapeType? type,
    List<Offset>? points,
    bool clear = false,
  }) {
    if (clear) {
      return const ActiveDrawingState();
    }
    return ActiveDrawingState(
      start: start ?? this.start,
      end: end ?? this.end,
      style: style ?? this.style,
      type: type ?? this.type,
      points: points ?? this.points,
    );
  }
}
