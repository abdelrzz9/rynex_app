import 'command.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import '../../../shapes/domain/entities/shape_type.dart';

class ModifyShapeCommand extends Command {
  final String shapeId;
  final ShapeEntity oldState;
  final ShapeEntity newState;
  final void Function(String, ShapeEntity) onUpdate;

  ModifyShapeCommand({
    required this.shapeId,
    required this.oldState,
    required this.newState,
    required this.onUpdate,
  });

  @override
  String get description => 'Modify ${oldState.type.label}';

  @override
  void execute() => onUpdate(shapeId, newState);

  @override
  void undo() => onUpdate(shapeId, oldState);
}
