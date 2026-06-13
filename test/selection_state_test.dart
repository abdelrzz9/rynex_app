import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/features/selection/domain/entities/selection_state.dart';

void main() {
  group('SelectionState', () {
    test('default state is empty', () {
      const state = SelectionState();
      expect(state.isEmpty, true);
      expect(state.isNotEmpty, false);
      expect(state.isSingle, false);
      expect(state.isMultiple, false);
      expect(state.hasMarquee, false);
      expect(state.hasActiveHandle, false);
    });

    test('select adds id', () {
      const state = SelectionState(selectedIds: {'a'});
      expect(state.isSelected('a'), true);
      expect(state.isSelected('b'), false);
      expect(state.isSingle, true);
      expect(state.isNotEmpty, true);
    });

    test('multiple selection', () {
      const state = SelectionState(selectedIds: {'a', 'b', 'c'});
      expect(state.isSingle, false);
      expect(state.isMultiple, true);
    });

    test('copyWith sets marquee', () {
      const state = SelectionState();
      final withMarquee = state.copyWith(marqueeRect: const Rect.fromLTWH(0, 0, 100, 100));
      expect(withMarquee.hasMarquee, true);
    });

    test('copyWith clears marquee', () {
      final state = SelectionState(marqueeRect: const Rect.fromLTWH(0, 0, 100, 100));
      final cleared = state.copyWith(clearMarquee: true);
      expect(cleared.hasMarquee, false);
    });

    test('copyWith clears active handle', () {
      final state = SelectionState(activeHandle: HandleType.topLeft);
      final cleared = state.copyWith(clearActiveHandle: true);
      expect(cleared.hasActiveHandle, false);
    });

    test('HandleType enum values', () {
      expect(HandleType.values.length, 9);
      expect(HandleType.values, contains(HandleType.rotation));
    });
  });
}
