import 'dart:convert';

import 'package:sudoku/logic/sudoku_generator.dart';

typedef _Move = ({int row, int col, int oldValue, int newValue});

class GameState {
  final int version;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final List<List<int>> board;
  final List<List<int>> solution;
  final List<List<bool>> isGiven;
  final List<List<bool>> isError;
  final List<List<Set<int>>> pencilMarks;
  final List<_Move> undoStack;
  final DateTime savedAt;

  GameState({
    this.version = 1,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.board,
    required this.solution,
    required this.isGiven,
    required this.isError,
    this.pencilMarks = const [],
    required this.undoStack,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'difficulty': difficulty.name,
      'elapsedSeconds': elapsedSeconds,
      'board': _parseBoard(board),
      'solution': _parseBoard(solution),
      'isGiven': _parseBoolBoard(isGiven),
      'isError': _parseBoolBoard(isError),
      'pencilMarks': pencilMarks.map((row) =>
        row.map((cell) => cell.toList()).toList()
      ).toList(),
      'undoStack': _parseUndoStack(undoStack),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int;
    if (version != 1) {
      throw Exception('Unsupported game state version: $version');
    }

    final difficultyString = json['difficulty'] as String;
    final difficulty = Difficulty.values.where((d) => d.name == difficultyString).firstOrNull;
    if (difficulty == null) {
      throw Exception('Invalid difficulty: "$difficultyString". Expected one of: ${Difficulty.values.map((d) => d.name).join(', ')}');
    }

    return GameState(
      version: version,
      difficulty: difficulty,
      elapsedSeconds: json['elapsedSeconds'] as int,
      board: _parseBoardFromJson(json['board'] as List),
      solution: _parseBoardFromJson(json['solution'] as List),
      isGiven: _parseBoolBoardFromJson(json['isGiven'] as List),
      isError: _parseBoolBoardFromJson(json['isError'] as List),
      pencilMarks: _parsePencilMarksFromJson(json['pencilMarks'] as List?),
      undoStack: _parseUndoStackFromJson(json['undoStack'] as List),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  static List<List<int>> _parseBoard(List<List<int>> board) {
    return board.map((row) => List<int>.from(row)).toList();
  }

  static List<List<int>> _parseBoardFromJson(List<dynamic> json) {
    if (json.length != 9) {
      throw Exception('Board must have 9 rows, got ${json.length}');
    }
    for (var i = 0; i < json.length; i++) {
      final row = json[i] as List<dynamic>;
      if (row.length != 9) {
        throw Exception('Board row $i must have 9 columns, got ${row.length}');
      }
      for (var j = 0; j < row.length; j++) {
        final value = row[j] as int;
        if (value < 0 || value > 9) {
          throw Exception('Board cell ($i, $j) must be 0-9, got $value');
        }
      }
    }
    return json
        .map((row) => (row as List<dynamic>).map((e) => e as int).toList())
        .toList();
  }

  static List<List<bool>> _parseBoolBoard(List<List<bool>> board) {
    return board.map((row) => List<bool>.from(row)).toList();
  }

  static List<List<bool>> _parseBoolBoardFromJson(List<dynamic> json) {
    if (json.length != 9) {
      throw Exception('Bool board must have 9 rows, got ${json.length}');
    }
    for (var i = 0; i < json.length; i++) {
      final row = json[i] as List<dynamic>;
      if (row.length != 9) {
        throw Exception('Bool board row $i must have 9 columns, got ${row.length}');
      }
    }
    return json
        .map((row) => (row as List<dynamic>).map((e) => e as bool).toList())
        .toList();
  }

  static List<Map<String, dynamic>> _parseUndoStack(List<_Move> stack) {
    return stack
        .map((move) => {
              'row': move.row,
              'col': move.col,
              'oldValue': move.oldValue,
              'newValue': move.newValue,
            })
        .toList();
  }

  static List<_Move> _parseUndoStackFromJson(List<dynamic> json) {
    return json
        .map((move) => (
              row: move['row'] as int,
              col: move['col'] as int,
              oldValue: move['oldValue'] as int,
              newValue: move['newValue'] as int,
            ))
        .toList();
  }

  static List<List<Set<int>>> _parsePencilMarksFromJson(List<dynamic>? json) {
    if (json == null) {
      return List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    }
    return json.map((row) =>
      (row as List<dynamic>).map((cell) =>
        (cell as List<dynamic>).map((e) => e as int).toSet()
      ).toList()
    ).toList();
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory GameState.fromJsonString(String jsonString) {
    return GameState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
