import 'dart:ui' show Rect;

import '../../../shapes/domain/entities/shape_entity.dart';
import 'command.dart';

enum AlignmentType {
  left,
  centerH,
  right,
  top,
  centerV,
  bottom,
  distributeH,
  distributeV,
}

class AlignShapesCommand extends Command {
  final List<ShapeEntity> shapes;
  final List<ShapeEntity> newStates;
  final void Function(String, ShapeEntity) onUpdate;

  AlignShapesCommand._({
    required this.shapes,
    required this.newStates,
    required this.onUpdate,
  });

  factory AlignShapesCommand({
    required List<ShapeEntity> shapes,
    required AlignmentType alignment,
    required void Function(String, ShapeEntity) onUpdate,
  }) {
    final newStates = _align(shapes, alignment);
    return AlignShapesCommand._(
      shapes: shapes,
      newStates: newStates,
      onUpdate: onUpdate,
    );
  }

  static List<ShapeEntity> _align(List<ShapeEntity> shapes, AlignmentType alignment) {
    final result = <ShapeEntity>[];
    final bounds = shapes.map((s) => s.boundingBox).toList();

    switch (alignment) {
      case AlignmentType.left:
        final target = bounds.map((b) => b.left).reduce((a, b) => a < b ? a : b);
        for (var i = 0; i < shapes.length; i++) {
          final dx = target - bounds[i].left;
          result.add(shapes[i].copyWith(boundingBox: bounds[i].translate(dx, 0)));
        }
      case AlignmentType.centerH:
        final min = bounds.map((b) => b.center.dx).reduce((a, b) => a < b ? a : b);
        final max = bounds.map((b) => b.center.dx).reduce((a, b) => a > b ? a : b);
        final target = min + (max - min) / 2;
        for (var i = 0; i < shapes.length; i++) {
          final dx = target - bounds[i].center.dx;
          result.add(shapes[i].copyWith(boundingBox: bounds[i].translate(dx, 0)));
        }
      case AlignmentType.right:
        final target = bounds.map((b) => b.right).reduce((a, b) => a > b ? a : b);
        for (var i = 0; i < shapes.length; i++) {
          final dx = target - bounds[i].right;
          result.add(shapes[i].copyWith(boundingBox: bounds[i].translate(dx, 0)));
        }
      case AlignmentType.top:
        final target = bounds.map((b) => b.top).reduce((a, b) => a < b ? a : b);
        for (var i = 0; i < shapes.length; i++) {
          final dy = target - bounds[i].top;
          result.add(shapes[i].copyWith(boundingBox: bounds[i].translate(0, dy)));
        }
      case AlignmentType.centerV:
        final min = bounds.map((b) => b.center.dy).reduce((a, b) => a < b ? a : b);
        final max = bounds.map((b) => b.center.dy).reduce((a, b) => a > b ? a : b);
        final target = min + (max - min) / 2;
        for (var i = 0; i < shapes.length; i++) {
          final dy = target - bounds[i].center.dy;
          result.add(shapes[i].copyWith(boundingBox: bounds[i].translate(0, dy)));
        }
      case AlignmentType.bottom:
        final target = bounds.map((b) => b.bottom).reduce((a, b) => a > b ? a : b);
        for (var i = 0; i < shapes.length; i++) {
          final dy = target - bounds[i].bottom;
          result.add(shapes[i].copyWith(boundingBox: bounds[i].translate(0, dy)));
        }
      case AlignmentType.distributeH:
        final sorted = List<Rect>.of(bounds)..sort((a, b) => a.center.dx.compareTo(b.center.dx));
        final minX = sorted.first.center.dx;
        final maxX = sorted.last.center.dx;
        final gap = shapes.length > 1 ? (maxX - minX) / (shapes.length - 1) : 0;
        for (var i = 0; i < shapes.length; i++) {
          final targetX = minX + gap * i;
          final dx = targetX - sorted[i].center.dx;
          final idx = bounds.indexOf(sorted[i]);
          result.add(shapes[idx].copyWith(boundingBox: bounds[idx].translate(dx, 0)));
        }
      case AlignmentType.distributeV:
        final sorted = List<Rect>.of(bounds)..sort((a, b) => a.center.dy.compareTo(b.center.dy));
        final minY = sorted.first.center.dy;
        final maxY = sorted.last.center.dy;
        final gap = shapes.length > 1 ? (maxY - minY) / (shapes.length - 1) : 0;
        for (var i = 0; i < shapes.length; i++) {
          final targetY = minY + gap * i;
          final dy = targetY - sorted[i].center.dy;
          final idx = bounds.indexOf(sorted[i]);
          result.add(shapes[idx].copyWith(boundingBox: bounds[idx].translate(0, dy)));
        }
    }
    return result;
  }

  @override
  String get description => 'Align shapes';

  @override
  void execute() {
    for (var i = 0; i < shapes.length; i++) {
      onUpdate(shapes[i].id, newStates[i]);
    }
  }

  @override
  void undo() {
    for (var i = 0; i < shapes.length; i++) {
      onUpdate(shapes[i].id, shapes[i]);
    }
  }
}
