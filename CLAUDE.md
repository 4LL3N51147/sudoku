# CLAUDE.md — Sudoku Codebase Guide

This file documents the structure, conventions, and workflows for the Sudoku Go project. It is intended to help AI assistants and developers understand and contribute to the codebase effectively.

---

## Project Overview

A Go implementation of a Sudoku board generator that uses constraint propagation. The program creates a 9x9 Sudoku board structured as a 3x3 grid of 3x3 blocks, populates cells with random values while tracking candidate elimination, and prints the remaining candidate sets for each cell.

**Current state:** Work-in-progress. The board is populated block-by-block with random values, propagating row/column/block constraints. A full backtracking solver is not yet implemented.

---

## Repository Structure

```
sudoku/
├── go.mod       # Go module definition (module: Sudoku, go 1.24)
├── main.go      # All application code (233 lines)
├── .gitignore   # Ignores .idea/ (GoLand IDE files)
└── CLAUDE.md    # This file
```

All logic lives in a single `main` package in `main.go`. There are no external dependencies.

---

## Technology Stack

| Item | Details |
|------|---------|
| Language | Go 1.24 |
| Module name | `Sudoku` |
| External dependencies | None |
| Standard libraries used | `fmt`, `math/rand`, `reflect`, `sort` |
| Build system | Go toolchain (`go build`, `go run`) |
| Tests | None yet |
| CI/CD | None |

---

## Core Data Model

The board is organized in a three-level hierarchy: `Cell` → `Block` → `Board`.

### `Cell` (lines 15–37)

```go
type Cell struct {
    Value      int
    Candidates map[int]struct{}
}
```

- `Value`: the assigned digit (1–9), or 0 if unset.
- `Candidates`: the set of digits still valid for this cell. Initialized to `{1..9}` and shrunk by constraint propagation.
- `Populate()`: picks a random key from `Candidates` using `reflect.ValueOf` and sets it as `Value`.

### `Block` (lines 39–134)

```go
type Block struct {
    RowCells map[int][]*Cell  // rows 0-2, each with 3 cells
    ColCells map[int][]*Cell  // cols 0-2, each with 3 cells (same pointers)
}
```

A 3×3 block. `RowCells` and `ColCells` share the same `*Cell` pointers — they are two views over the same nine cells.

Key methods:
- `Populate()` — fills each cell randomly and calls `UpdateCandidates` within the block after each assignment.
- `UpdateCandidates(n int)` — removes `n` from every cell's candidate set (block-level constraint).
- `UpdateRowCandidate(r int, nums []int)` — removes `nums` from candidates of cells in local row `r`.
- `UpdateColCandidate(c int, nums []int)` — removes `nums` from candidates of cells in local column `c`.
- `Values() [][]int` — returns the 3×3 grid of assigned values.
- `Print()` / `PrintCandidates()` — display helpers.

### `Board` (lines 136–233)

```go
type Board struct {
    RowBlocks map[int][]*Block  // block rows 0-2, each with 3 blocks
    ColBlocks map[int][]*Block  // block cols 0-2 (same pointers)
}
```

A 9×9 board made of a 3×3 arrangement of `Block`s. `RowBlocks` and `ColBlocks` share the same `*Block` pointers.

Key methods:
- `UpdateRowCandidate(rowNum int, n []int)` — propagates constraints across all three blocks in the global row `rowNum`. Maps global row → block row via `rowNum/3` and local row via `rowNum%3`.
- `UpdateColCandidate(colNum int, n []int)` — same for columns.
- `UpdateByBlock(bi, bj int, block *Block)` — after a block is populated, propagates its row and column values across the whole board.
- `Populate()` — iterates blocks in row-major order, populates each, then propagates constraints.
- `Print()` / `PrintCandidates()` — display helpers.

### `main()` (lines 10–13)

```go
func main() {
    b := NewBoard()
    b.PrintCandidates()
}
```

Creates a new board (which does **not** auto-populate on construction) and prints the candidate map. Note: `NewBoard()` does not call `Populate()` — the board is empty and every cell has all 9 candidates when `PrintCandidates()` is called. To see a populated board, call `b.Populate()` before `b.PrintCandidates()`.

---

## Coordinate System

Understanding the two-level indexing is critical:

| Concept | Variable pattern | Example |
|---------|-----------------|---------|
| Global row (0–8) | `rowNum` | row 5 |
| Block row (0–2) | `rowNum / 3` | block row 1 |
| Local row within block (0–2) | `rowNum % 3` | local row 2 |
| Global column (0–8) | `colNum` | col 7 |
| Block column (0–2) | `colNum / 3` | block col 2 |
| Local column within block (0–2) | `colNum % 3` | local col 1 |

---

## Build & Run

```bash
# Run directly
go run main.go

# Build binary
go build -o sudoku .
./sudoku

# No tests exist yet
go test ./...   # will report "no test files"
```

---

## Known Issues / Limitations

1. **`main()` does not call `Populate()`** — the program prints candidates for an empty (all-9-candidates) board. This is likely a bug; `b.Populate()` should be called before `b.PrintCandidates()`.

2. **`reflect` used for map keys** — `Cell.Populate()` uses `reflect.ValueOf(c.Candidates).MapKeys()` to pick a random candidate. This can be replaced with a simpler idiomatic Go loop.

3. **Random, not solved** — blocks are populated with random values without backtracking. The resulting board may not be a valid Sudoku solution; constraint propagation only narrows candidates, it does not guarantee a complete valid assignment.

4. **Map iteration order is non-deterministic** — `Block.Populate()` and `Board.Populate()` iterate over Go maps, so cell fill order varies per run. Consistent results require either sorted iteration or seeding `math/rand`.

5. **No tests** — there are no `*_test.go` files. Adding tests for constraint propagation logic would significantly improve reliability.

---

## Conventions

- **Constructor naming:** `New<Type>()` returns a pointer (e.g., `NewCell()`, `NewBlock()`, `NewBoard()`).
- **Pointer receivers:** all methods use pointer receivers (`*Cell`, `*Block`, `*Board`).
- **Candidate set:** `map[int]struct{}` is used as an idiomatic Go set.
- **Shared pointers:** `RowCells`/`ColCells` in `Block` and `RowBlocks`/`ColBlocks` in `Board` share pointers intentionally so mutations via one view are visible through the other.
- **No error handling:** none is needed for the current pure in-memory logic; continue this pattern unless I/O or external state is introduced.
- **Single package:** all code lives in `package main`. Introduce sub-packages only when the file grows substantially or logical boundaries demand it.

---

## Development Workflow

```bash
# Verify code compiles
go build ./...

# Format code (run before every commit)
go fmt ./...

# Vet for common issues
go vet ./...

# Run tests when they exist
go test ./...
```

There is no Makefile or pre-commit hook. It is recommended to run `go fmt` and `go vet` manually before committing.

---

## Git Workflow

- **Active branch:** `claude/claude-md-mm1sjfpehjrszxxo-sLeNK`
- **Default branch:** `master`
- There is a single initial commit (`a3a2d7a`, message: `"1"`).
- Commit messages should be descriptive. The existing `"1"` style should not be repeated.

---

## Suggested Next Steps

The following are areas where the codebase could be extended (do not implement unless explicitly requested):

- Call `b.Populate()` in `main()` before printing.
- Replace `reflect`-based random selection in `Cell.Populate()` with a plain map iteration.
- Add a backtracking solver to guarantee valid Sudoku boards.
- Add `*_test.go` files covering at minimum: candidate initialization, `UpdateCandidates`, `UpdateRowCandidate`, `UpdateColCandidate`, and `UpdateByBlock`.
- Add deterministic seeding or a `-seed` flag for reproducible output.
