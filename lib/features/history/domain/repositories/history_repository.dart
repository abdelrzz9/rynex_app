import '../commands/command.dart';

abstract class HistoryRepository {
  bool get canUndo;
  bool get canRedo;
  void execute(Command command);
  void undo();
  void redo();
  void clear();
}
