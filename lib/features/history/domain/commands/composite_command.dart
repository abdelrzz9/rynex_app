import 'command.dart';

class CompositeCommand extends Command {
  final List<Command> commands;

  CompositeCommand(this.commands);

  @override
  String get description {
    if (commands.isEmpty) return 'No operation';
    if (commands.length == 1) return commands.first.description;
    return '${commands.length} operations';
  }

  @override
  void execute() {
    for (final cmd in commands) {
      cmd.execute();
    }
  }

  @override
  void undo() {
    for (final cmd in commands.reversed) {
      cmd.undo();
    }
  }
}
