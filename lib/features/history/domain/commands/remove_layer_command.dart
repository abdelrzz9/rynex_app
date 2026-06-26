import '../../../layers/domain/entities/layer.dart';
import '../../../shapes/domain/entities/shape_entity.dart';
import 'command.dart';
import 'composite_command.dart';
import 'remove_shape_command.dart';

class RemoveLayerCommand extends Command {
  final LayerEntity layer;
  final List<ShapeEntity> shapes;
  final void Function(LayerEntity) onAddLayer;
  final void Function(int) onRemoveLayer;
  final void Function(ShapeEntity) onAddShape;
  final void Function(String) onRemoveShape;

  late final CompositeCommand _removeShapesCommand;

  RemoveLayerCommand({
    required this.layer,
    required this.shapes,
    required this.onAddLayer,
    required this.onRemoveLayer,
    required this.onAddShape,
    required this.onRemoveShape,
  }) {
    final shapeCommands = shapes.map((s) => RemoveShapeCommand(
      shape: s,
      onAdd: onAddShape,
      onRemove: onRemoveShape,
    ) as Command).toList();
    _removeShapesCommand = CompositeCommand(shapeCommands);
  }

  @override
  String get description => 'Remove layer ${layer.name}';

  @override
  void execute() {
    _removeShapesCommand.execute();
    onRemoveLayer(layer.id);
  }

  @override
  void undo() {
    onAddLayer(layer);
    _removeShapesCommand.undo();
  }
}
