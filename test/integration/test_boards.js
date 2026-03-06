/**
 * Predefined Sudoku boards for strategy testing
 *
 * Each board is designed to have a specific solving pattern available
 */

// A valid completed Sudoku solution
const COMPLETED_SOLUTION = [
  [1, 2, 3, 4, 5, 6, 7, 8, 9],
  [4, 5, 6, 7, 8, 9, 1, 2, 3],
  [7, 8, 9, 1, 2, 3, 4, 5, 6],
  [2, 3, 4, 5, 6, 7, 8, 9, 1],
  [5, 6, 7, 8, 9, 1, 2, 3, 4],
  [8, 9, 1, 2, 3, 4, 5, 6, 7],
  [3, 4, 5, 6, 7, 8, 9, 1, 2],
  [6, 7, 8, 9, 1, 2, 3, 4, 5],
  [9, 1, 2, 3, 4, 5, 6, 7, 8]
];

// Helper to create isGiven array
function createIsGiven(board) {
  return board.map(row => row.map(cell => cell !== 0));
}

// Helper to create empty isError array
function createIsError() {
  return Array(9).fill(null).map(() => Array(9).fill(false));
}

// Helper to create an empty undoStack
function createUndoStack() {
  return [];
}

// HIDDEN SINGLE BOARD
// Row 0 is missing one number at position (0, 8) - the 9
// This creates a hidden single in row 0
const HIDDEN_SINGLE_BOARD = {
  version: 1,
  difficulty: 'easy',
  elapsedSeconds: 0,
  board: [
    [1, 2, 3, 4, 5, 6, 7, 8, 0],  // Row 0: missing 9
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  solution: COMPLETED_SOLUTION,
  isGiven: createIsGiven([
    [1, 2, 3, 4, 5, 6, 7, 8, 0],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ]),
  isError: createIsError(),
  undoStack: createUndoStack(),
  savedAt: new Date().toISOString()
};

// NAKED PAIR BOARD
// Row 0 has two cells with only {2, 4} as candidates
// Position (0, 2) and (0, 6) both have digits that form a naked pair
const NAKED_PAIR_BOARD = {
  version: 1,
  difficulty: 'medium',
  elapsedSeconds: 0,
  board: [
    [1, 3, 0, 5, 6, 0, 0, 8, 9],  // Row 0: cells (0,2) and (0,5) can form naked pair
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  solution: COMPLETED_SOLUTION,
  isGiven: createIsGiven([
    [1, 3, 0, 5, 6, 0, 0, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ]),
  isError: createIsError(),
  undoStack: createUndoStack(),
  savedAt: new Date().toISOString()
};

// HIDDEN PAIR BOARD
// Box 0 (top-left 3x3) has two cells with only digits {3, 7} appearing in exactly those cells
const HIDDEN_PAIR_BOARD = {
  version: 1,
  difficulty: 'medium',
  elapsedSeconds: 0,
  board: [
    [1, 2, 0, 4, 5, 6, 7, 8, 9],
    [4, 5, 0, 7, 8, 9, 1, 2, 3],
    [7, 8, 0, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  solution: COMPLETED_SOLUTION,
  isGiven: createIsGiven([
    [1, 2, 0, 4, 5, 6, 7, 8, 9],
    [4, 5, 0, 7, 8, 9, 1, 2, 3],
    [7, 8, 0, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ]),
  isError: createIsError(),
  undoStack: createUndoStack(),
  savedAt: new Date().toISOString()
};

// NAKED TRIPLE BOARD
// Row 0 has three cells that form a naked triple
const NAKED_TRIPLE_BOARD = {
  version: 1,
  difficulty: 'hard',
  elapsedSeconds: 0,
  board: [
    [0, 0, 0, 4, 5, 6, 7, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  solution: COMPLETED_SOLUTION,
  isGiven: createIsGiven([
    [0, 0, 0, 4, 5, 6, 7, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ]),
  isError: createIsError(),
  undoStack: createUndoStack(),
  savedAt: new Date().toISOString()
};

// HIDDEN TRIPLE BOARD
const HIDDEN_TRIPLE_BOARD = {
  version: 1,
  difficulty: 'hard',
  elapsedSeconds: 0,
  board: [
    [1, 2, 0, 0, 0, 6, 7, 8, 9],
    [4, 5, 0, 0, 0, 9, 1, 2, 3],
    [7, 8, 0, 0, 0, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  solution: COMPLETED_SOLUTION,
  isGiven: createIsGiven([
    [1, 2, 0, 0, 0, 6, 7, 8, 9],
    [4, 5, 0, 0, 0, 9, 1, 2, 3],
    [7, 8, 0, 0, 0, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ]),
  isError: createIsError(),
  undoStack: createUndoStack(),
  savedAt: new Date().toISOString()
};

// NAKED QUAD BOARD
const NAKED_QUAD_BOARD = {
  version: 1,
  difficulty: 'hard',
  elapsedSeconds: 0,
  board: [
    [0, 0, 0, 0, 5, 6, 7, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  solution: COMPLETED_SOLUTION,
  isGiven: createIsGiven([
    [0, 0, 0, 0, 5, 6, 7, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ]),
  isError: createIsError(),
  undoStack: createUndoStack(),
  savedAt: new Date().toISOString()
};

// HIDDEN QUAD BOARD
const HIDDEN_QUAD_BOARD = {
  version: 1,
  difficulty: 'hard',
  elapsedSeconds: 0,
  board: [
    [0, 0, 0, 0, 5, 6, 7, 8, 9],
    [0, 0, 0, 0, 8, 9, 1, 2, 3],
    [0, 0, 0, 0, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  solution: COMPLETED_SOLUTION,
  isGiven: createIsGiven([
    [0, 0, 0, 0, 5, 6, 7, 8, 9],
    [0, 0, 0, 0, 8, 9, 1, 2, 3],
    [0, 0, 0, 0, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ]),
  isError: createIsError(),
  undoStack: createUndoStack(),
  savedAt: new Date().toISOString()
};

module.exports = {
  HIDDEN_SINGLE_BOARD,
  NAKED_PAIR_BOARD,
  HIDDEN_PAIR_BOARD,
  NAKED_TRIPLE_BOARD,
  HIDDEN_TRIPLE_BOARD,
  NAKED_QUAD_BOARD,
  HIDDEN_QUAD_BOARD
};
