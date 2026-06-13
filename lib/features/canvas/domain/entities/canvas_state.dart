import 'package:equatable/equatable.dart';
import 'canvas_transform.dart';

class CanvasState extends Equatable {
  final CanvasTransform transform;
  final bool showGrid;
  final bool snapToGrid;

  const CanvasState({
    this.transform = const CanvasTransform(),
    this.showGrid = true,
    this.snapToGrid = false,
  });

  CanvasState copyWith({
    CanvasTransform? transform,
    bool? showGrid,
    bool? snapToGrid,
  }) {
    return CanvasState(
      transform: transform ?? this.transform,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
    );
  }

  @override
  List<Object?> get props => [transform, showGrid, snapToGrid];
}
