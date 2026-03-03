# Sudoku Integration Tests

Playwright-based integration tests for the Sudoku Flutter web application.

## Prerequisites

1. Install Node.js
2. Install Playwright browsers:
   ```bash
   npx playwright install chromium
   ```

## Setup

1. Start the web server:
   ```bash
   flutter build web
   python3 -m http.server 8080 --directory build/web
   ```

2. Install dependencies:
   ```bash
   cd test/integration
   npm install
   ```

## Running Tests

Run all tests:
```bash
npm test
# or
bash run_tests.sh
```

Run individual tests:
```bash
node new_game_test.js
node hint_test.js
node settings_test.js
```

## Test Files

| File | Description |
|------|-------------|
| `new_game_test.js` | Tests starting games at each difficulty |
| `number_input_test.js` | Tests cell selection and number input |
| `hint_test.js` | Tests strategy hint system |
| `import_export_test.js` | Tests game import/export |
| `settings_test.js` | Tests settings dialog |
| `run_tests.sh` | Test runner script |

## Adding New Tests

1. Create a new `.js` file in this directory
2. Follow the pattern of existing tests
3. Add the test to `run_tests.sh`
