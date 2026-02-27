import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/game_state.dart';
import 'package:sudoku/logic/sudoku_generator.dart';

void main() {
  group('GameState', () {
    test('serializes to JSON with all fields', () {
      final state = GameState(
        difficulty: Difficulty.easy,
        elapsedSeconds: 120,
        board: List.generate(9, (r) => List.generate(9, (c) => r == c ? r + 1 : 0)),
        solution: List.generate(9, (r) => List.generate(9, (c) => (c + 1) % 9 + 1)),
        isGiven: List.generate(9, (r) => List.generate(9, (c) => r == c)),
        isError: List.generate(9, (_) => List.filled(9, false)),
        undoStack: [],
        savedAt: DateTime.parse('2026-02-27T10:00:00Z'),
      );

      final json = state.toJson();

      expect(json['version'], 1);
      expect(json['difficulty'], 'easy');
      expect(json['elapsedSeconds'], 120);
      expect(json['board'], isA<List>());
      expect(json['savedAt'], '2026-02-27T10:00:00.000Z');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'version': 1,
        'difficulty': 'medium',
        'elapsedSeconds': 60,
        'board': List.generate(9, (_) => List.filled(9, 0)),
        'solution': List.generate(9, (r) => List.generate(9, (c) => (c + 1) % 9 + 1)),
        'isGiven': List.generate(9, (_) => List.filled(9, false)),
        'isError': List.generate(9, (_) => List.filled(9, false)),
        'undoStack': <Map<String, dynamic>>[],
        'savedAt': '2026-02-27T10:00:00.000Z',
      };

      final state = GameState.fromJson(json);

      expect(state.difficulty, Difficulty.medium);
      expect(state.elapsedSeconds, 60);
      expect(state.version, 1);
    });

    test('throws on invalid version', () {
      final json = {
        'version': 999,
        'difficulty': 'easy',
        'elapsedSeconds': 0,
        'board': List.generate(9, (_) => List.filled(9, 0)),
        'solution': List.generate(9, (_) => List.filled(9, 0)),
        'isGiven': List.generate(9, (_) => List.filled(9, false)),
        'isError': List.generate(9, (_) => List.filled(9, false)),
        'undoStack': [],
        'savedAt': '2026-02-27T10:00:00.000Z',
      };

      expect(() => GameState.fromJson(json), throwsA(isA<Exception>()));
    });
  });
}
