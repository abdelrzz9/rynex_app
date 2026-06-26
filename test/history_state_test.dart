import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/features/history/domain/commands/command.dart';
import 'package:rynex_app/features/history/domain/entities/history_state.dart';

class _TestCommand extends Command {
  @override
  void execute() {}

  @override
  void undo() {}

  @override
  String get description => 'test';
}

void main() {
  group('HistoryState equality', () {
    test('different stacks with same length are not equal', () {
      final cmd1 = _TestCommand();
      final cmd2 = _TestCommand();
      final cmd3 = _TestCommand();

      final stateWithTwo = HistoryState(undoStack: [cmd1, cmd2], redoStack: const []);
      final stateAfterRedoThenNewCmd = HistoryState(
        undoStack: [cmd1, cmd3],
        redoStack: const [],
      );

      expect(stateWithTwo == stateAfterRedoThenNewCmd, isFalse,
          reason: 'Stacks have same length (2) but different command IDs');
    });

    test('same sequences are equal', () {
      final cmd1 = _TestCommand();
      final cmd2 = _TestCommand();

      final s1 = HistoryState(undoStack: [cmd1, cmd2], redoStack: const []);
      final s2 = HistoryState(undoStack: [cmd1, cmd2], redoStack: const []);
      expect(s1 == s2, isTrue);
    });

    test('empty states are equal', () {
      const s1 = HistoryState();
      const s2 = HistoryState();
      expect(s1 == s2, isTrue);
    });

    test('states with different redo commands are not equal', () {
      final cmd1 = _TestCommand();
      final cmd2 = _TestCommand();

      final s1 = HistoryState(undoStack: [cmd1], redoStack: [cmd2]);
      final s2 = HistoryState(undoStack: [cmd1], redoStack: [cmd2]);
      expect(s1 == s2, isTrue, reason: 'Same commands in same order');

      final cmd3 = _TestCommand();
      final s3 = HistoryState(undoStack: [cmd1], redoStack: [cmd3]);
      expect(s1 == s3, isFalse, reason: 'Redo stacks have different command IDs');
    });
  });
}
