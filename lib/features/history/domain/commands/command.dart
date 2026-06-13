abstract class Command {
  void execute();
  void undo();
  String get description;
}
