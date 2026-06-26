abstract class Command {
  static int _nextId = 0;
  final int id = _nextId++;

  void execute();
  void undo();
  String get description;
}
