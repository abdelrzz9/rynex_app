import 'package:equatable/equatable.dart';
import 'canvas_transform.dart';

class CanvasState extends Equatable {
  final CanvasTransform transform;
  final bool showGrid;
  final bool snapToGrid;
  final double canvasWidth;
  final double canvasHeight;
  final String canvasSizeLabel;

  const CanvasState({
    this.transform = const CanvasTransform(),
    this.showGrid = true,
    this.snapToGrid = false,
    this.canvasWidth = 800,
    this.canvasHeight = 1100,
    this.canvasSizeLabel = 'A4',
  });

  CanvasState copyWith({
    CanvasTransform? transform,
    bool? showGrid,
    bool? snapToGrid,
    double? canvasWidth,
    double? canvasHeight,
    String? canvasSizeLabel,
  }) {
    return CanvasState(
      transform: transform ?? this.transform,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      canvasSizeLabel: canvasSizeLabel ?? this.canvasSizeLabel,
    );
  }

  @override
  List<Object?> get props => [
        transform,
        showGrid,
        snapToGrid,
        canvasWidth,
        canvasHeight,
        canvasSizeLabel,
      ];
}
