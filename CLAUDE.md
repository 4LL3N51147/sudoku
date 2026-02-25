# CLAUDE.md — Sudoku Codebase Guide

This file documents the structure, conventions, and workflows for the Sudoku Go project. It is intended to help AI assistants and developers understand and contribute to the codebase effectively.

---

## Project Overview

A Go project for building a Sudoku application. The codebase has been reset to a blank slate and is ready for a fresh implementation.

**Current state:** Empty skeleton. `main.go` contains only `package main` and an empty `main()` function.

---

## Repository Structure

```
sudoku/
├── go.mod       # Go module definition (module: Sudoku, go 1.24)
├── main.go      # Entry point (empty skeleton)
├── .gitignore   # Ignores .idea/ (GoLand IDE files)
└── CLAUDE.md    # This file
```

All code lives in a single `main` package. There are no external dependencies.

---

## Technology Stack

| Item | Details |
|------|---------|
| Language | Go 1.24 |
| Module name | `Sudoku` |
| External dependencies | None |
| Build system | Go toolchain (`go build`, `go run`) |
| Tests | None yet |
| CI/CD | None |

---

## Build & Run

```bash
# Run directly
go run main.go

# Build binary
go build -o sudoku .
./sudoku

# Run tests (none exist yet)
go test ./...
```

---

## Conventions

- **Constructor naming:** `New<Type>()` returns a pointer.
- **Pointer receivers:** use pointer receivers for all methods.
- **Single package:** all code lives in `package main`. Introduce sub-packages only when the file grows substantially or logical boundaries demand it.
- **No error handling** for pure in-memory logic; add it when I/O or external state is introduced.

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

There is no Makefile or pre-commit hook. Run `go fmt` and `go vet` manually before committing.

---

## Git Workflow

- **Active branch:** `claude/claude-md-mm1sjfpehjrszxxo-sLeNK`
- **Default branch:** `master`
- Commit messages should be descriptive.
