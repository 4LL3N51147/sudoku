import 'dart:async';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/sudoku_generator.dart';
import '../logic/strategy_solver.dart';
import '../logic/game_state.dart';
import '../logic/game_board.dart';
import '../logic/selection_model.dart';
import '../widgets/game_board_container.dart';
import '../app_settings.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/game_header.dart';
import '../widgets/hint_controller.dart';


class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final GameState? initialState;  // Add this

  const GameScreen({
    super.key,
    required this.difficulty,
    this.initialState,  // Add this
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameBoard _gameBoard;
  final SelectionModel _selection = SelectionModel();

  bool _isPaused = false;
  bool _isAnimating = false;
  bool _isCompleted = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  StrategyHighlight? _strategyHighlight;
  String? _hintMessage;
  int? _hintPhase; // null = no hint, 0 = scan, 1 = elimination, 2 = target
  StrategyResult? _currentStrategyResult;
  List<HintStep> _hintSteps = []; // Steps from strategy result
  bool _useHintSteps = false; // Whether to use hintSteps
  Map<(int, int), Set<int>> _candidates = {};
  Map<(int, int), Set<int>> _userPencilMarks = {};
  bool _isPencilMode = false;
  Set<int> _completedDigits = {};  // Track digits placed in all 9 blocks
  AppSettings _settings = const AppSettings();

  Set<int>? _getSelectedCellCandidates() {
    if (_selection.row < 0 || _selection.col < 0) return null;
    return _candidates[(_selection.row, _selection.col)];
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _newGame();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    if (mounted) setState(() => _settings = settings);
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_isAnimating) return false;

    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // Digits 1-9 (number row and numpad)
    final digitKeys = {
      LogicalKeyboardKey.digit1: 1, LogicalKeyboardKey.digit2: 2,
      LogicalKeyboardKey.digit3: 3, LogicalKeyboardKey.digit4: 4,
      LogicalKeyboardKey.digit5: 5, LogicalKeyboardKey.digit6: 6,
      LogicalKeyboardKey.digit7: 7, LogicalKeyboardKey.digit8: 8,
      LogicalKeyboardKey.digit9: 9,
      LogicalKeyboardKey.numpad1: 1, LogicalKeyboardKey.numpad2: 2,
      LogicalKeyboardKey.numpad3: 3, LogicalKeyboardKey.numpad4: 4,
      LogicalKeyboardKey.numpad5: 5, LogicalKeyboardKey.numpad6: 6,
      LogicalKeyboardKey.numpad7: 7, LogicalKeyboardKey.numpad8: 8,
      LogicalKeyboardKey.numpad9: 9,
    };
    if (digitKeys.containsKey(key) && !isCtrl) {
      _onNumberInput(digitKeys[key]!);
      return true;
    }

    // Erase: Backspace or Delete
    if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      _onErase();
      return true;
    }

    // Ctrl+Z: Undo
    if (isCtrl && key == LogicalKeyboardKey.keyZ) {
      _undo();
      return true;
    }

    // Ctrl+S: Export
    if (isCtrl && key == LogicalKeyboardKey.keyS) {
      _exportGame();
      return true;
    }

    // H: Hint
    if (key == LogicalKeyboardKey.keyH && !isCtrl) {
      _showStrategyPicker();
      return true;
    }

    // Space: Pause/resume
    if (key == LogicalKeyboardKey.space && !isCtrl) {
      _togglePause();
      return true;
    }

    return false;
  }

  void _newGame() {
    if (widget.initialState != null) {
      // Load from imported state
      final state = widget.initialState!;
      _gameBoard = GameBoard(
        puzzle: state.board,
        solution: state.solution,
      );
      // Restore given cells
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (state.isGiven[r][c] && state.board[r][c] != 0) {
            _gameBoard.setCell(r, c, state.board[r][c]);
          }
        }
      }
      _elapsedSeconds = state.elapsedSeconds;
    } else {
      // Generate new game
      final result = SudokuGenerator.generate(widget.difficulty);
      _gameBoard = GameBoard(
        puzzle: result.puzzle,
        solution: result.solution,
      );
      _elapsedSeconds = 0;
    }
    // Keep the rest of the initialization:
    _candidates = {};
    _completedDigits = _calculateCompletedDigits();
    _selection.clear();
    _isPaused = false;
    _isAnimating = false;
    _isCompleted = false;
    _strategyHighlight = null;
    _hintMessage = null;
    _hintPhase = null;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && !_isAnimating && !_isCompleted && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _onCellTap(int row, int col) {
    if (_isPaused || _isAnimating || _isCompleted) return;
    setState(() {
      _selection.select(row, col);
    });
  }

  void _onNumberInput(int num) {
    if (_isPaused || _isAnimating || _isCompleted) return;
    if (_selection.row < 0 || _selection.col < 0) return;
    if (_gameBoard.isGivenCell(_selection.row, _selection.col)) return;

    if (_isPencilMode) {
      // Pencil mode: toggle digit in candidates (only on empty cells)
      if (_gameBoard.board[_selection.row][_selection.col] != 0) return;
      setState(() {
        _togglePencilMark(_selection.row, _selection.col, num);
      });
    } else {
      // Pen mode: fill cell (existing behavior)
      if (_gameBoard.board[_selection.row][_selection.col] == num) return;
      setState(() {
        _fillCell(_selection.row, _selection.col, num);
      });
    }
  }

  void _togglePencilMark(int row, int col, int digit) {
    final key = (row, col);
    final existing = _userPencilMarks[key] ?? <int>{};

    if (existing.contains(digit)) {
      // Remove the digit
      if (existing.length == 1) {
        _userPencilMarks.remove(key);
      } else {
        _userPencilMarks[key] = {...existing}..remove(digit);
      }
    } else {
      // Add the digit
      _userPencilMarks[key] = {...existing, digit};
    }
  }

  void _onErase() {
    if (_isPaused || _isAnimating || _isCompleted) return;
    if (_selection.row < 0 || _selection.col < 0) return;
    if (_gameBoard.isGivenCell(_selection.row, _selection.col)) return;

    if (_isPencilMode) {
      // Pencil mode: clear candidates for this cell
      setState(() {
        _candidates.remove((_selection.row, _selection.col));
      });
    } else {
      // Pen mode: clear cell value (existing behavior)
      if (_gameBoard.board[_selection.row][_selection.col] == 0) return;
      setState(() {
        _gameBoard.eraseCell(_selection.row, _selection.col);
        _updateErrors();
        _candidates = computeCandidates(_gameBoard.board);
        _completedDigits = _calculateCompletedDigits();
      });
    }
  }

  void _onTogglePencilMode() {
    if (_isPaused || _isAnimating || _isCompleted) return;
    setState(() {
      _isPencilMode = !_isPencilMode;
    });
  }

  void _fillCell(int row, int col, int digit) {
    // Use GameBoard to set cell (includes undo stack and error update)
    _gameBoard.setCell(row, col, digit);

    // Check if the filled digit is correct (matches solution)
    final isCorrect = _gameBoard.board[row][col] == _gameBoard.solution[row][col];

    // Only update candidates if the fill is correct
    // This preserves candidates for undo restoration on incorrect fills
    if (isCorrect) {
      // Update candidates incrementally - only if candidates exist
      if (_candidates.isEmpty) {
        _candidates = computeCandidates(_gameBoard.board);
      } else {
        _candidates = _updateCandidatesAfterFill(_candidates, row, col, digit);
      }

      // Also update userPencilMarks for affected cells
      _userPencilMarks = _updateCandidatesAfterFill(_userPencilMarks, row, col, digit);
    }
    // If incorrect, don't update candidates - they'll be restored on undo

    // Track completed digits
    _updateCompletedDigits(digit);

    // Check win
    if (_gameBoard.checkWin()) {
      _isCompleted = true;
      _timer?.cancel();
      _showWinDialog();
    }
  }

  void _updateCompletedDigits(int digit) {
    // Count occurrences of this digit on the board
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_gameBoard.board[r][c] == digit) count++;
      }
    }
    if (count >= 9) {
      _completedDigits = {..._completedDigits, digit};
    }
  }

  void _undo() {
    if (_isPaused || _isAnimating || _isCompleted || !_gameBoard.canUndo) return;
    setState(() {
      _gameBoard.undo();
      _selection.select(_selection.row, _selection.col);
      _completedDigits = _calculateCompletedDigits();
    });
  }

  void _updateErrors() {
    _gameBoard.updateErrors();
  }

  /// Update candidates incrementally after filling a cell.
  /// Removes the filled digit from related cells while preserving manual eliminations.
  Map<(int, int), Set<int>> _updateCandidatesAfterFill(
    Map<(int, int), Set<int>> candidates,
    int filledRow,
    int filledCol,
    int digit,
  ) {
    final updated = <(int, int), Set<int>>{};
    for (final entry in candidates.entries) {
      final cell = entry.key;
      final cellRow = cell.$1;
      final cellCol = cell.$2;
      if (cellRow == filledRow && cellCol == filledCol) continue;
      final sharesRow = cellRow == filledRow;
      final sharesCol = cellCol == filledCol;
      final sharesBox = ((cellRow ~/ 3) == (filledRow ~/ 3)) &&
          ((cellCol ~/ 3) == (filledCol ~/ 3));
      if (sharesRow || sharesCol || sharesBox) {
        final newCandidates = Set<int>.from(entry.value)..remove(digit);
        if (newCandidates.isNotEmpty) {
          updated[cell] = newCandidates;
        }
      } else {
        updated[cell] = entry.value;
      }
    }
    return updated;
  }

  Set<int> _calculateCompletedDigits() {
    final completed = <int>{};
    for (int digit = 1; digit <= 9; digit++) {
      int count = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (_gameBoard.board[r][c] == digit) count++;
        }
      }
      if (count >= 9) completed.add(digit);
    }
    return completed;
  }

  bool _checkWin() {
    return _gameBoard.checkWin();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showWinDialog() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Puzzle Solved!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 64),
              const SizedBox(height: 12),
              Text(
                'Time: ${_formatTime(_elapsedSeconds)}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Menu'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(_newGame);
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    });
  }

  void _advanceHintPhase() {
    if (_hintPhase == null) return; // no hint active
    if (_isPaused || _isCompleted) return;

    final strategy = _currentStrategyResult;
    if (strategy == null) return;

    // Use hintSteps if available
    if (strategy.hintSteps.isNotEmpty) {
      _useHintSteps = true;
      _hintSteps = strategy.hintSteps;
    }
    
    _advanceHintPhaseStrategy(strategy);
  }

  void _advanceHintPhaseStrategy(StrategyResult result) {
    // Use hintSteps if available
    if (_useHintSteps && _hintSteps.isNotEmpty) {
      // Check if there are more steps
      final nextIndex = (_hintPhase ?? 0) + 1;
      if (nextIndex < _hintSteps.length) {
        setState(() {
          _hintPhase = nextIndex;
          final step = _hintSteps[nextIndex];
          _hintMessage = step.message;
          _strategyHighlight = StrategyHighlight(
            phase: step.phase,
            unitCells: step.unitCells,
            patternCells: step.patternCells,
            eliminatorCells: step.eliminatorCells,
            patternDigits: step.patternDigits,
            targetCell: step.targetCell,
            unitType: step.unitType,
            eliminationCandidates: step.eliminationCandidates,
            eliminationRows: step.eliminationRows,
            eliminationCols: step.eliminationCols,
            eliminationBoxes: step.eliminationBoxes,
            resultCells: step.resultCells,
          );
        });
      } else {
        // No more steps - finish the hint
        _applyHintResult(result);
      }
      return;
    }
    
    // Fall back to old behavior
    // For Hidden Single, skip phase 1 - go from scan to elimination to target
    final isHiddenSingle = result.type == StrategyType.hiddenSingle;
    if (isHiddenSingle && _hintPhase == 1) {
      // Skip phase 1 (pattern) and phase 2 (elimination) for Hidden Single
      setState(() {
        _hintPhase = 3; // Go directly to target
        final unitLabel = result.unitType != null
            ? switch (result.unitType!) {
                UnitType.row => 'row',
                UnitType.column => 'column',
                UnitType.box => 'box',
              }
            : 'board';
        final digit = result.patternDigits.first;
        _hintMessage = 'Found $digit in this $unitLabel!';
        _strategyHighlight = StrategyHighlight(
          phase: StrategyPhase.target,
          unitCells: result.unitCells,
          patternCells: result.patternCells,
          patternDigits: result.patternDigits,
          targetCell: result.targetCell,
          unitType: result.unitType,
        );
      });
      return;
    }
    
    if (_hintPhase! < 3) {
      // Advance to next phase
      setState(() {
        _hintPhase = _hintPhase! + 1;
        final unitLabel = result.unitType != null
            ? switch (result.unitType!) {
                UnitType.row => 'row',
                UnitType.column => 'column',
                UnitType.box => 'box',
              }
            : 'board';

        // Determine strategy type for messaging
        final isNaked = result.type == StrategyType.nakedPair ||
            result.type == StrategyType.nakedTriple ||
            result.type == StrategyType.nakedQuad;
        final isHidden = result.type == StrategyType.hiddenPair ||
            result.type == StrategyType.hiddenTriple ||
            result.type == StrategyType.hiddenQuad;
        final digits = result.patternDigits;
        final numCells = result.patternCells.length;

        if (_hintPhase == 1) {
          // Phase 1: Show the pattern - what was found
          if (result.type == StrategyType.nakedPair) {
            // Naked Pair: these 2 digits are locked in these 2 cells
            _hintMessage = 'Naked Pair: $digits are locked in these 2 cells';
          } else if (result.type == StrategyType.nakedTriple) {
            // Naked Triple: these 3 digits are locked in these 3 cells
            _hintMessage = 'Naked Triple: $digits are locked in these 3 cells';
          } else if (result.type == StrategyType.nakedQuad) {
            // Naked Quad: these 4 digits are locked in these 4 cells
            _hintMessage = 'Naked Quad: $digits are locked in these 4 cells';
          } else if (result.type == StrategyType.hiddenPair) {
            // Hidden Pair: look for 2 digits that appear in exactly 2 cells - don't reveal which cells yet
            _hintMessage = 'Looking for Hidden Pair: $digits in this $unitLabel';
          } else if (result.type == StrategyType.hiddenTriple) {
            // Hidden Triple: look for 3 digits that appear in exactly 3 cells - don't reveal which cells yet
            _hintMessage = 'Looking for Hidden Triple: $digits in this $unitLabel';
          } else if (result.type == StrategyType.hiddenQuad) {
            // Hidden Quad: look for 4 digits that appear in exactly 4 cells - don't reveal which cells yet
            _hintMessage = 'Looking for Hidden Quad: $digits in this $unitLabel';
          } else {
            _hintMessage = 'Found $digits in this $unitLabel';
          }
          // For hidden strategies, don't highlight specific cells in scan phase - 
          // user can't know which cells until after elimination
          // For naked strategies, show the pattern cells
          final showPatternCells = isNaked;
          _strategyHighlight = StrategyHighlight(
            phase: StrategyPhase.scan,
            unitCells: result.unitCells,
            patternCells: showPatternCells ? result.patternCells : {},
            patternDigits: result.patternDigits,
            unitType: result.unitType,
          );
        } else if (_hintPhase == 2) {
          // Phase 2: Show elimination - what to remove
          final elimCount = result.eliminationCells.length;
          if (isNaked) {
            // Naked: remove these digits from OTHER cells in unit
            _hintMessage = 'Remove $digits from $elimCount other cell${elimCount > 1 ? 's' : ''} in this $unitLabel';
          } else if (isHidden) {
            // Hidden: remove OTHER candidates from these $numCells cells
            _hintMessage = 'Remove other candidates from these $numCells cells';
          } else {
            _hintMessage = '${result.patternDigits} can only go in ${result.patternCells.length} cell(s)!';
          }
          // Show elimination with zones
          _strategyHighlight = StrategyHighlight(
            phase: StrategyPhase.elimination,
            unitCells: result.unitCells,
            eliminatorCells: result.eliminationCells,
            patternCells: result.patternCells,
            patternDigits: result.patternDigits,
            eliminationCandidates: result.eliminationCandidates,
            eliminationRows: result.eliminationRows,
            eliminationCols: result.eliminationCols,
            eliminationBoxes: result.eliminationBoxes,
            targetCell: result.targetCell,
            unitType: result.unitType,
          );
        } else if (_hintPhase == 3) {
          // Phase 3: Show target/result - cells that can now be filled
          if (isNaked && result.resultCells.isNotEmpty) {
            // Naked strategies: show cells that now have single candidates
            final resultCount = result.resultCells.length;
            _hintMessage = 'Now you can fill $resultCount cell${resultCount > 1 ? 's' : ''} with single candidates!';
            // Highlight result cells in green
            _strategyHighlight = StrategyHighlight(
              phase: StrategyPhase.target,
              unitCells: result.unitCells,
              patternCells: result.patternCells,
              resultCells: result.resultCells,
              patternDigits: result.patternDigits,
              targetCell: result.targetCell,
              unitType: result.unitType,
            );
          } else if (isHidden) {
            // Hidden strategies: highlight pattern cells as the result (digits are locked)
            _hintMessage = 'These cells are now locked to $digits!';
            // Highlight pattern cells in green as the result
            _strategyHighlight = StrategyHighlight(
              phase: StrategyPhase.target,
              unitCells: result.unitCells,
              patternCells: result.patternCells,
              patternDigits: result.patternDigits,
              targetCell: result.targetCell,
              unitType: result.unitType,
            );
          } else if (result.targetCell != null) {
            // Hidden Single: show the target cell
            final digit = result.patternDigits.first;
            _hintMessage = 'Now you can place $digit in this cell!';
            _strategyHighlight = StrategyHighlight(
              phase: StrategyPhase.target,
              unitCells: result.unitCells,
              patternCells: result.patternCells,
              patternDigits: result.patternDigits,
              targetCell: result.targetCell,
              unitType: result.unitType,
            );
          } else {
            // Fallback - skip to completion
            _hintPhase = 4; // Will trigger completion in next check
          }
        }
      });
    } else if (_useHintSteps && (_hintPhase ?? 0) >= _hintSteps.length - 1) {
      // All hintSteps completed - finish the hint
      _applyHintResult(result);
    } else {
      // Phase 2 complete - if there's a target cell, fill it
      if (result.targetCell != null) {
        final (row, col) = result.targetCell!;
        // For Hidden Single, automatically fill the digit
        // For other strategies, let the user fill manually
        final bool shouldAutoFill = result.type == StrategyType.hiddenSingle;
        setState(() {
          if (shouldAutoFill) {
            // Fill the cell automatically for Hidden Single
            _gameBoard.setCell(row, col, result.patternDigits.first);
            _updateErrors();
            // Update candidates incrementally - preserve existing pencil marks
            _candidates = _updateCandidatesAfterFill(_candidates, row, col, result.patternDigits.first);
          }
          // Apply elimination candidates to _candidates
          if (result.eliminationCandidates.isNotEmpty) {
            final updated = Map<(int, int), Set<int>>.from(_candidates);
            for (final entry in result.eliminationCandidates.entries) {
              final cell = entry.key;
              final digits = entry.value;
              if (updated.containsKey(cell)) {
                updated[cell] = updated[cell]!.difference(digits);
              }
            }
            _candidates = updated;
          }
          _strategyHighlight = null;
          _hintMessage = null;
          _hintPhase = null;
          _currentStrategyResult = null;
          _isAnimating = false;
          _selection.select(row, col);
        });
      } else {
        // Elimination only - apply eliminations to candidates
        setState(() {
          if (result.eliminationCandidates.isNotEmpty) {
            final updated = Map<(int, int), Set<int>>.from(_candidates);
            for (final entry in result.eliminationCandidates.entries) {
              final cell = entry.key;
              final digits = entry.value;
              if (updated.containsKey(cell)) {
                updated[cell] = updated[cell]!.difference(digits);
              }
            }
            _candidates = updated;
          }
          _strategyHighlight = null;
          _hintMessage = null;
          _hintPhase = null;
          _currentStrategyResult = null;
          _isAnimating = false;
        });
      }
    }
  }

  void _applyHintResult(StrategyResult result) {
    // Apply the hint result - fill target cell or apply eliminations
    if (result.targetCell != null) {
      final (row, col) = result.targetCell!;
      final bool shouldAutoFill = result.type == StrategyType.hiddenSingle;
      setState(() {
        if (shouldAutoFill) {
          _gameBoard.setCell(row, col, result.patternDigits.first);
          _updateErrors();
          // Update candidates incrementally - preserve existing pencil marks
          _candidates = _updateCandidatesAfterFill(_candidates, row, col, result.patternDigits.first);
        }
        // Apply elimination candidates
        if (result.eliminationCandidates.isNotEmpty) {
          final updated = Map<(int, int), Set<int>>.from(_candidates);
          for (final entry in result.eliminationCandidates.entries) {
            final cell = entry.key;
            final digits = entry.value;
            if (updated.containsKey(cell)) {
              updated[cell] = updated[cell]!.difference(digits);
            }
          }
          _candidates = updated;
        }
        _strategyHighlight = null;
        _hintMessage = null;
        _hintPhase = null;
        _currentStrategyResult = null;
        _hintSteps = [];
        _useHintSteps = false;
        _isAnimating = false;
        _selection.select(row, col);
      });
    } else {
      setState(() {
        if (result.eliminationCandidates.isNotEmpty) {
          final updated = Map<(int, int), Set<int>>.from(_candidates);
          for (final entry in result.eliminationCandidates.entries) {
            final cell = entry.key;
            final digits = entry.value;
            if (updated.containsKey(cell)) {
              updated[cell] = updated[cell]!.difference(digits);
            }
          }
          _candidates = updated;
        }
        _strategyHighlight = null;
        _hintMessage = null;
        _hintPhase = null;
        _currentStrategyResult = null;
        _hintSteps = [];
        _useHintSteps = false;
        _isAnimating = false;
      });
    }
  }

  void _showStrategyPicker() {
    HintController.showStrategyPicker(
      context: context,
      onStrategySelected: _runStrategyHint,
      showAdvancedHints: _settings.showAdvancedHints,
    );
  }

  Future<void> _runStrategyHint(StrategyType type) async {
    // For non-HiddenSingle strategies, compute candidates first
    if (type != StrategyType.hiddenSingle) {
      setState(() {
        // Only compute candidates if empty - preserves manual eliminations
        if (_candidates.isEmpty) {
          _candidates = computeCandidates(_gameBoard.board);
        }
      });
    }

    // Pass existing candidates if available to preserve manual eliminations
    final solver = StrategySolver(
      _gameBoard.board,
      _candidates.isNotEmpty ? _candidates : null,
    );
    final result = switch (type) {
      StrategyType.hiddenSingle => solver.findHiddenSingle(),
      StrategyType.nakedPair => solver.findNakedPair(),
      StrategyType.hiddenPair => solver.findHiddenPair(),
      StrategyType.nakedTriple => solver.findNakedTriple(),
      StrategyType.hiddenTriple => solver.findHiddenTriple(),
      StrategyType.nakedQuad => solver.findNakedQuad(),
      StrategyType.hiddenQuad => solver.findHiddenQuad(),
    };

    if (result == null) {
      if (!mounted) return;
      final name = type.name.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => ' ${m.group(1)}',
      ).trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $name found on this board.')),
      );
      return;
    }

    _currentStrategyResult = result;
    final unitLabel = result.unitType != null
        ? switch (result.unitType!) {
            UnitType.row => 'row',
            UnitType.column => 'column',
            UnitType.box => 'box',
          }
        : 'board';

    // If skip animation is enabled, apply immediately with no UI
    if (_settings.skipHintAnimation) {
      if (type == StrategyType.hiddenSingle) {
        // Hidden Single always has a targetCell (solver contract)
        assert(result.targetCell != null, 'Hidden Single result must have a targetCell');
        final (row, col) = result.targetCell!;
        setState(() {
          // Use setCell which properly handles the undo stack
          _gameBoard.setCell(row, col, result.patternDigits.first);
          // Don't compute candidates - they should only be shown for elimination strategies
          _updateErrors();
          _strategyHighlight = null;
          _hintMessage = null;
          _hintPhase = null;
          _currentStrategyResult = null;
          _isAnimating = false;
          _selection.select(row, col);
          if (_checkWin()) {
            _isCompleted = true;
            _timer?.cancel();
          }
        });
        if (_isCompleted) _showWinDialog();
      } else {
        // Elimination strategy: apply eliminations to candidates
        setState(() {
          final updated = Map<(int, int), Set<int>>.from(_candidates);
          for (final entry in result.eliminationCandidates.entries) {
            final cell = entry.key;
            final digits = entry.value;
            if (updated.containsKey(cell)) {
              updated[cell] = updated[cell]!.difference(digits);
            }
          }
          _candidates = updated;
          _strategyHighlight = null;
          _hintMessage = null;
          _hintPhase = null;
          _currentStrategyResult = null;
          _isAnimating = false;
        });
        final strategyName = type.name.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(1)}',
        ).trim();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$strategyName applied — candidates updated')),
          );
        }
      }
      return;
    }

    // For non-HiddenSingle, show candidates phase first
    if (type != StrategyType.hiddenSingle) {
      setState(() {
        _isAnimating = true;
        _hintPhase = -1; // Special phase for showing candidates
        _hintMessage = 'Computing candidates for all cells...';
      });
      // Short delay then proceed to scan phase
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Phase 0 — scan: highlight the unit
    setState(() {
      _isAnimating = true;
      _hintPhase = 0;
      _hintMessage = 'Scanning this $unitLabel — looking for ${result.patternDigits}';
      _strategyHighlight = StrategyHighlight(
        phase: StrategyPhase.scan,
        unitCells: result.unitCells,
        patternDigits: result.patternDigits,
        unitType: result.unitType,
      );
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SettingsSheet(
        settings: _settings,
        onChanged: (newSettings) {
          setState(() => _settings = newSettings);
          newSettings.save();
        },
      ),
    );
  }

  void _exportGame() {
    final state = GameState(
      difficulty: widget.difficulty,
      elapsedSeconds: _elapsedSeconds,
      board: _gameBoard.board,
      solution: _gameBoard.solution,
      isGiven: _gameBoard.isGivenBoard,
      isError: _gameBoard.isErrorBoard,
      undoStack: _gameBoard.undoStack,
      savedAt: DateTime.now(),
    );

    final jsonString = state.toJsonString();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Encode the JSON string as a data URL for cross-platform compatibility
      final encoded = Uri.encodeComponent(jsonString);
      final dataUrl = 'data:application/json;charset=utf-8,$encoded';
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = dataUrl
        ..setAttribute('download', 'sudoku-${widget.difficulty.name}-$timestamp.sudoku');
      anchor.click();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game exported!')),
      );
    } catch (e) {
      // Show error instead of misleading success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  String _difficultyLabel() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return Stack(
              children: [
                isWide ? _buildWideLayout() : _buildNarrowLayout(),
                if (_isPaused) PauseOverlay(
        onResume: _togglePause,
        onQuit: () {
          _timer?.cancel();
          Navigator.pop(context);
        },
      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isWide: true),
        const SizedBox(height: 12),
        Expanded(
          child: GameBoardContainer(
            board: _gameBoard.board,
            isGiven: _gameBoard.isGivenBoard,
            isError: _gameBoard.isErrorBoard,
            selectedRow: _selection.row,
            selectedCol: _selection.col,
            isPaused: _isPaused,
            isAnimating: _isAnimating,
            strategyHighlight: _strategyHighlight,
            candidates: _candidates,
            matchingCandidates: _getSelectedCellCandidates(),
            disabledDigits: _completedDigits,
            hintMessage: _hintMessage,
            hintPhase: _hintPhase,
            isCompleted: _isCompleted,
            isPencilMode: _isPencilMode,
            onTogglePencilMode: _onTogglePencilMode,
            onNextPressed: _advanceHintPhase,
            onCellTap: _onCellTap,
            onNumberInput: _onNumberInput,
            onErase: _onErase,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isWide: false),
        const SizedBox(height: 12),
        Expanded(
          child: GameBoardContainer(
            board: _gameBoard.board,
            isGiven: _gameBoard.isGivenBoard,
            isError: _gameBoard.isErrorBoard,
            selectedRow: _selection.row,
            selectedCol: _selection.col,
            isPaused: _isPaused,
            isAnimating: _isAnimating,
            strategyHighlight: _strategyHighlight,
            candidates: _candidates,
            matchingCandidates: _getSelectedCellCandidates(),
            disabledDigits: _completedDigits,
            hintMessage: _hintMessage,
            hintPhase: _hintPhase,
            isCompleted: _isCompleted,
            isPencilMode: _isPencilMode,
            onTogglePencilMode: _onTogglePencilMode,
            onNextPressed: _advanceHintPhase,
            onCellTap: _onCellTap,
            onNumberInput: _onNumberInput,
            onErase: _onErase,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool isWide}) {
    // Mobile layout: compact header with title on its own row
    if (!isWide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Back, Undo, Settings, New Game, Timer/Pause, Export, Hint
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: (_isPaused || _isAnimating || _isCompleted || !_gameBoard.canUndo)
                      ? null
                      : _undo,
                  color: const Color(0xFF1A237E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  onPressed: (_isPaused || _isAnimating || _isCompleted)
                      ? null
                      : _showSettings,
                  color: const Color(0xFF1A237E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                // New Game button
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: (_isPaused || _isAnimating || _isCompleted)
                      ? null
                      : _newGame,
                  color: const Color(0xFF1A237E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'New Game',
                ),
                const Spacer(),
                // Timer and Pause
                GameHeader(
                  elapsedSeconds: _elapsedSeconds,
                  isPaused: _isPaused,
                  isAnimating: _isAnimating,
                  onPauseToggle: _togglePause,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  onPressed: (_isPaused || _isAnimating || _isCompleted)
                      ? null
                      : _exportGame,
                  color: const Color(0xFF1A237E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.lightbulb_outline, size: 20),
                  onPressed: (_isPaused || _isAnimating || _isCompleted)
                      ? null
                      : _showStrategyPicker,
                  color: const Color(0xFF1A237E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Row 2: Title with Difficulty
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'SUDOKU - ${_difficultyLabel().toUpperCase()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
        ],
      );
    } else {
    // Desktop layout: original wide header
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: (_isPaused || _isAnimating || _isCompleted || !_gameBoard.canUndo)
                ? null
                : _undo,
            color: const Color(0xFF1A237E),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: (_isPaused || _isAnimating || _isCompleted)
                ? null
                : _showSettings,
            color: const Color(0xFF1A237E),
          ),
          // New Game button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isPaused || _isAnimating || _isCompleted)
                ? null
                : _newGame,
            color: const Color(0xFF1A237E),
            tooltip: 'New Game',
          ),
          const Expanded(
            child: Text(
              'SUDOKU',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
          // Add difficulty label after title
          Text(
            '- ${_difficultyLabel().toUpperCase()}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          // Timer, Pause, Export, Hint - all on the right side
          GameHeader(
            elapsedSeconds: _elapsedSeconds,
            isPaused: _isPaused,
            isAnimating: _isAnimating,
            onPauseToggle: _togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: (_isPaused || _isAnimating || _isCompleted)
                ? null
                : _exportGame,
            color: const Color(0xFF1A237E),
            iconSize: 26,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: (_isPaused || _isAnimating || _isCompleted)
                ? null
                : _showStrategyPicker,
            color: const Color(0xFF1A237E),
            iconSize: 26,
          ),
        ],
      ),
    );
    }
  }

}
