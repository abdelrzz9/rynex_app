import 'command.dart';

class ReorderShapeCommand extends Command {
  final String shapeId;
  final int oldOrder;
  final int newOrder;
  final void Function(String, int) onReorder;

  ReorderShapeCommand({
    required this.shapeId,
    required this.oldOrder,
    required this.newOrder,
    required this.onReorder,
  });

  @override
  String get description => 'Reorder shape';

  @override
  void execute() => onReorder(shapeId, newOrder);

  @override
  void undo() => onReorder(shapeId, oldOrder);
}
