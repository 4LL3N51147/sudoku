import 'package:flutter/material.dart';
import '../logic/strategy_solver.dart';
import 'sudoku_board.dart';
import 'number_pad.dart';
import 'hint_banner.dart';

/// Container widget that holds the SudokuBoard and NumberPad,
/// handling wide vs narrow layout based on screen width.
class GameBoardContainer extends StatelessWidget {
  // SudokuBoard props
  final List<List<int>> board;
  final List<List<bool>> isGiven;
  final List<List<bool>> isError;
  final int selectedRow;
  final int selectedCol;
  final bool isPaused;
  final bool isAnimating;
  final StrategyHighlight? strategyHighlight;
  final Map<(int, int), Set<int>>? candidates;
  final Set<int>? matchingCandidates;

  // NumberPad props
  final Set<int>? disabledDigits;

  // HintBanner props
  final String? hintMessage;
  final int? hintPhase;
  final bool isCompleted;
  final VoidCallback? onNextPressed;

  // Callbacks with animation guards
  final void Function(int row, int col) onCellTap;
  final void Function(int) onNumberInput;
  final VoidCallback onErase;

  const GameBoardContainer({
    super.key,
    required this.board,
    required this.isGiven,
    required this.isError,
    required this.selectedRow,
    required this.selectedCol,
    required this.isPaused,
    required this.isAnimating,
    this.strategyHighlight,
    this.candidates,
    this.matchingCandidates,
    this.disabledDigits,
    this.hintMessage,
    this.hintPhase,
    required this.isCompleted,
    this.onNextPressed,
    required this.onCellTap,
    required this.onNumberInput,
    required this.onErase,
  });

  void _handleCellTap(int row, int col) {
    if (isPaused || isAnimating || isCompleted) return;
    onCellTap(row, col);
  }

  void _handleNumberInput(int num) {
    if (isPaused || isAnimating || isCompleted) return;
    onNumberInput(num);
  }

  void _handleErase() {
    if (isPaused || isAnimating || isCompleted) return;
    onErase();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 12),
              child: AspectRatio(
                aspectRatio: 1,
                child: SudokuBoard(
                  board: board,
                  isGiven: isGiven,
                  isError: isError,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                  isPaused: isPaused,
                  onCellTap: _handleCellTap,
                  strategyHighlight: strategyHighlight,
                  candidates: candidates,
                  matchingCandidates: matchingCandidates,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Reserve space for hint banner to prevent layout shift
        SizedBox(
          height: hintMessage != null ? 52 : 0,
          child: hintMessage != null
              ? HintBanner(
                  message: hintMessage!,
                  hasNextButton: hintPhase != null && hintPhase! <= 3,
                  onNextPressed:
                      (isPaused || isCompleted) ? null : onNextPressed,
                )
              : const SizedBox(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: NumberPad(
            onNumber: _handleNumberInput,
            onErase: _handleErase,
            disabledDigits: disabledDigits,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
