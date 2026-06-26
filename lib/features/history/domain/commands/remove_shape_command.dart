import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/domain/entities/shape_type.dart';
import 'command.dart';

class RemoveShapeCommand extends Command {
  final ShapeEntity shape;
  final void Function(ShapeEntity) onAdd;
  final void Function(String) onRemove;

  RemoveShapeCommand({
    required this.shape,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  String get description => 'Remove ${shape.type.label}';

  @override
  void execute() => onRemove(shape.id);

  @override
  void undo() => onAdd(shape);
}
