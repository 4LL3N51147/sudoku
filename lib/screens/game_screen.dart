import 'dart:async';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/sudoku_generator.dart';
import '../logic/strategy_solver.dart';
import '../logic/game_state.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/number_pad.dart';
import '../app_settings.dart';
import '../widgets/settings_sheet.dart';

typedef _Move = ({int row, int col, int oldValue, int newValue});

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
  late List<List<int>> _solution;
  late List<List<bool>> _isGiven;
  late List<List<int>> _board;
  late List<List<bool>> _isError;

  int _selectedRow = -1;
  int _selectedCol = -1;
  bool _isPaused = false;
  bool _isAnimating = false;
  bool _isCompleted = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  StrategyHighlight? _strategyHighlight;
  String? _hintMessage;
  int? _hintPhase; // null = no hint, 0 = scan, 1 = elimination, 2 = target
  HiddenSingleResult? _currentHintResult;
  StrategyResult? _currentStrategyResult;
  Map<(int, int), Set<int>> _candidates = {};
  final List<_Move> _undoStack = [];
  AppSettings _settings = const AppSettings();

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
      _runHiddenSingleHint();
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
      _solution = state.solution;
      _isGiven = state.isGiven;
      _board = state.board.map((row) => List<int>.from(row)).toList();
      _isError = state.isError.map((row) => List<bool>.from(row)).toList();
      _undoStack.clear();
      _undoStack.addAll(state.undoStack);
      _elapsedSeconds = state.elapsedSeconds;
    } else {
      // Generate new game (existing code)
      final result = SudokuGenerator.generate(widget.difficulty);
      _solution = result.solution;
      _isGiven = List.generate(
          9, (r) => List.generate(9, (c) => result.puzzle[r][c] != 0));
      _board = result.puzzle.map((row) => List<int>.from(row)).toList();
      _isError = List.generate(9, (_) => List.filled(9, false));
      _undoStack.clear();
      _elapsedSeconds = 0;
    }
    // Keep the rest of the initialization:
    _selectedRow = -1;
    _selectedCol = -1;
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
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumberInput(int num) {
    if (_isPaused || _isAnimating || _isCompleted) return;
    if (_selectedRow < 0 || _selectedCol < 0) return;
    if (_isGiven[_selectedRow][_selectedCol]) return;
    if (_board[_selectedRow][_selectedCol] == num) return;  // no-op guard
    setState(() {
      _undoStack.add((
        row: _selectedRow,
        col: _selectedCol,
        oldValue: _board[_selectedRow][_selectedCol],
        newValue: num,
      ));
      _board[_selectedRow][_selectedCol] = num;
      _updateErrors();
      if (_checkWin()) {
        _isCompleted = true;
        _timer?.cancel();
        _showWinDialog();
      }
    });
  }

  void _onErase() {
    if (_isPaused || _isAnimating || _isCompleted) return;
    if (_selectedRow < 0 || _selectedCol < 0) return;
    if (_isGiven[_selectedRow][_selectedCol]) return;
    if (_board[_selectedRow][_selectedCol] == 0) return;  // no-op guard
    setState(() {
      _undoStack.add((
        row: _selectedRow,
        col: _selectedCol,
        oldValue: _board[_selectedRow][_selectedCol],
        newValue: 0,
      ));
      _board[_selectedRow][_selectedCol] = 0;
      _updateErrors();
    });
  }

  void _undo() {
    if (_isPaused || _isAnimating || _isCompleted || _undoStack.isEmpty) return;
    setState(() {
      final move = _undoStack.removeLast();
      _board[move.row][move.col] = move.oldValue;
      _selectedRow = move.row;
      _selectedCol = move.col;
      _updateErrors();
    });
  }

  void _updateErrors() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (!_isGiven[r][c] && _board[r][c] != 0) {
          _isError[r][c] = _board[r][c] != _solution[r][c];
        } else {
          _isError[r][c] = false;
        }
      }
    }
  }

  bool _checkWin() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board[r][c] != _solution[r][c]) return false;
      }
    }
    return true;
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

  Future<void> _runHiddenSingleHint() async {
    final result = findHiddenSingle(_board);
    if (result == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hidden singles on this board.')),
      );
      return;
    }

    _currentHintResult = result;
    final unitLabel = switch (result.unitType) {
      UnitType.row => 'row',
      UnitType.column => 'column',
      UnitType.box => 'box',
    };

    // Phase 0 — scan: highlight the unit
    setState(() {
      _isAnimating = true;
      _hintPhase = 0;
      _hintMessage =
          'Scanning this $unitLabel — looking for digit ${result.digit}';
      _strategyHighlight = StrategyHighlight(
        phase: StrategyPhase.scan,
        unitCells: result.unitCells,
        unitType: result.unitType,
      );
    });
  }

  void _advanceHintPhase() {
    if (_hintPhase == null) return; // no hint active
    if (_isPaused || _isCompleted) return;

    // Check if we're using the old HiddenSingleResult or new StrategyResult
    final hiddenSingle = _currentHintResult;
    final strategy = _currentStrategyResult;

    if (hiddenSingle == null && strategy == null) return;

    // Handle legacy HiddenSingleResult
    if (hiddenSingle != null && strategy == null) {
      _advanceHintPhaseLegacy(hiddenSingle);
      return;
    }

    // Handle new StrategyResult
    if (strategy != null) {
      _advanceHintPhaseStrategy(strategy);
    }
  }

  void _advanceHintPhaseLegacy(HiddenSingleResult result) {
    if (_hintPhase! < 2) {
      // Advance to next phase
      setState(() {
        _hintPhase = _hintPhase! + 1;
        final unitLabel = switch (result.unitType) {
          UnitType.row => 'row',
          UnitType.column => 'column',
          UnitType.box => 'box',
        };

        if (_hintPhase == 1) {
          // Elimination phase
          _hintMessage =
              'These filled cells prevent ${result.digit} from going elsewhere in this $unitLabel';
          _strategyHighlight = StrategyHighlight(
            phase: StrategyPhase.elimination,
            unitCells: result.unitCells,
            eliminatorCells: result.eliminatorCells,
            unitType: result.unitType,
          );
        } else if (_hintPhase == 2) {
          // Target phase
          _hintMessage =
              '${result.digit} has only one valid cell left in this $unitLabel!';
          _strategyHighlight = StrategyHighlight(
            phase: StrategyPhase.target,
            unitCells: result.unitCells,
            eliminatorCells: result.eliminatorCells,
            targetCell: (result.row, result.col),
            unitType: result.unitType,
          );
        }
      });
    } else {
      // Phase 2 complete - fill the cell
      setState(() {
        final oldValue = _board[result.row][result.col];
        _undoStack.add((
          row: result.row,
          col: result.col,
          oldValue: oldValue,
          newValue: result.digit,
        ));
        _board[result.row][result.col] = result.digit;
        _updateErrors();
        _strategyHighlight = null;
        _hintMessage = null;
        _hintPhase = null;
        _currentHintResult = null;
        _isAnimating = false;
        _selectedRow = result.row;
        _selectedCol = result.col;
        if (_checkWin()) {
          _isCompleted = true;
          _timer?.cancel();
        }
      });
      if (_isCompleted) _showWinDialog();
    }
  }

  void _advanceHintPhaseStrategy(StrategyResult result) {
    if (_hintPhase! < 2) {
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

        if (_hintPhase == 1) {
          // Elimination phase
          _hintMessage = 'These cells block ${result.patternDigits} in this $unitLabel';
          _strategyHighlight = StrategyHighlight(
            phase: StrategyPhase.elimination,
            unitCells: result.unitCells,
            eliminatorCells: result.eliminationCells,
            unitType: result.unitType,
          );
        } else if (_hintPhase == 2) {
          // Target phase
          _hintMessage = '${result.patternDigits} can only go in ${result.patternCells.length} cell(s)!';
          _strategyHighlight = StrategyHighlight(
            phase: StrategyPhase.target,
            unitCells: result.unitCells,
            patternCells: result.patternCells,
            targetCell: result.targetCell,
            unitType: result.unitType,
          );
        }
      });
    } else {
      // Phase 2 complete - if there's a target cell, fill it
      if (result.targetCell != null) {
        final (row, col) = result.targetCell!;
        setState(() {
          final oldValue = _board[row][col];
          // For most strategies, we need to determine which digit to fill
          // For now, just highlight the cell - the user can fill it
          _strategyHighlight = null;
          _hintMessage = null;
          _hintPhase = null;
          _currentStrategyResult = null;
          _isAnimating = false;
          _selectedRow = row;
          _selectedCol = col;
        });
      } else {
        // No target cell (elimination only) - just clear the hint
        setState(() {
          _strategyHighlight = null;
          _hintMessage = null;
          _hintPhase = null;
          _currentStrategyResult = null;
          _isAnimating = false;
        });
      }
    }
  }

  void _showStrategyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Choose a Strategy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            _strategyTile(
              'Hidden Single',
              'Find a digit that can only go in one cell within a row, column, or box',
              () => _runStrategyHint(StrategyType.hiddenSingle),
            ),
            _strategyTile(
              'Naked Pair',
              'Find two cells in a unit with the same two candidates',
              () => _runStrategyHint(StrategyType.nakedPair),
            ),
            _strategyTile(
              'Hidden Pair',
              'Find two cells in a unit that are the only ones for two digits',
              () => _runStrategyHint(StrategyType.hiddenPair),
            ),
            _strategyTile(
              'Naked Triple',
              'Find three cells in a unit with the same three candidates',
              () => _runStrategyHint(StrategyType.nakedTriple),
            ),
            _strategyTile(
              'Hidden Triple',
              'Find three cells in a unit that are the only ones for three digits',
              () => _runStrategyHint(StrategyType.hiddenTriple),
            ),
            _strategyTile(
              'Naked Quad',
              'Find four cells in a unit with the same four candidates',
              () => _runStrategyHint(StrategyType.nakedQuad),
            ),
            _strategyTile(
              'Hidden Quad',
              'Find four cells in a unit that are the only ones for four digits',
              () => _runStrategyHint(StrategyType.hiddenQuad),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strategyTile(String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF1A237E)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _runStrategyHint(StrategyType type) async {
    // For non-HiddenSingle strategies, compute candidates first
    if (type != StrategyType.hiddenSingle) {
      setState(() {
        _candidates = computeCandidates(_board);
      });
    }

    final solver = StrategySolver(_board);
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
      board: _board,
      solution: _solution,
      isGiven: _isGiven,
      isError: _isError,
      undoStack: _undoStack,
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
                if (_isPaused) _buildPauseOverlay(),
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
          child: Center(
            child: SudokuBoard(
              board: _board,
              isGiven: _isGiven,
              isError: _isError,
              selectedRow: _selectedRow,
              selectedCol: _selectedCol,
              isPaused: _isPaused,
              onCellTap: _onCellTap,
              strategyHighlight: _strategyHighlight,
              candidates: _candidates,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_hintMessage != null) _buildHintBanner(_hintMessage!),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: NumberPad(
            onNumber: _onNumberInput,
            onErase: _onErase,
          ),
        ),
        const SizedBox(height: 12),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: SudokuBoard(
                board: _board,
                isGiven: _isGiven,
                isError: _isError,
                selectedRow: _selectedRow,
                selectedCol: _selectedCol,
                isPaused: _isPaused,
                onCellTap: _onCellTap,
                strategyHighlight: _strategyHighlight,
                candidates: _candidates,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_hintMessage != null) _buildHintBanner(_hintMessage!),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: NumberPad(
            onNumber: _onNumberInput,
            onErase: _onErase,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader({required bool isWide}) {
    // Mobile layout: compact header with title on its own row
    if (!isWide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Back, Undo, Settings, Timer, Export, Hint, Pause
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
                  onPressed: (_isPaused || _isAnimating || _isCompleted || _undoStack.isEmpty)
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
                const Spacer(),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
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
                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20),
                  onPressed: _isAnimating ? null : _togglePause,
                  color: const Color(0xFF1A237E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Row 2: Title and difficulty
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SUDOKU',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  _difficultyLabel(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
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
            onPressed: (_isPaused || _isAnimating || _isCompleted || _undoStack.isEmpty)
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SUDOKU',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  _difficultyLabel(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(_elapsedSeconds),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              fontFamily: 'monospace',
            ),
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
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            onPressed: _isAnimating ? null : _togglePause,
            color: const Color(0xFF1A237E),
            iconSize: 28,
          ),
        ],
      ),
    );
    }
  }

  Widget _buildHintBanner(String message) {
    final bool hasNextButton = _hintPhase != null && _hintPhase! <= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A237E), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFF1A237E), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
            if (hasNextButton) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: (_isPaused || _isCompleted)
                    ? null
                    : _advanceHintPhase,
                child: const Text(
                  'Next \u2192',
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle_filled_rounded,
                      size: 64, color: Color(0xFF1A237E)),
                  const SizedBox(height: 12),
                  const Text(
                    'Game Paused',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume',
                        style: TextStyle(fontSize: 17)),
                    onPressed: _togglePause,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Quit to Menu',
                      style: TextStyle(color: Colors.redAccent, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
