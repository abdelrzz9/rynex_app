import 'package:equatable/equatable.dart';
import '../commands/command.dart';

class HistoryState extends Equatable {
  final List<Command> undoStack;
  final List<Command> redoStack;
  final int maxSize;

  const HistoryState({
    this.undoStack = const [],
    this.redoStack = const [],
    this.maxSize = 10000,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  HistoryState copyWith({
    List<Command>? undoStack,
    List<Command>? redoStack,
    int? maxSize,
  }) {
    return HistoryState(
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      maxSize: maxSize ?? this.maxSize,
    );
  }

  @override
  List<Object?> get props => [undoStack.length, redoStack.length, maxSize];
}
