import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/domain/entities/shape_type.dart';
import 'command.dart';

class AddShapeCommand extends Command {
  final ShapeEntity shape;
  final void Function(ShapeEntity) onAdd;
  final void Function(String) onRemove;

  AddShapeCommand({
    required this.shape,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  String get description => 'Add ${shape.type.label}';

  @override
  void execute() => onAdd(shape);

  @override
  void undo() => onRemove(shape.id);
}
