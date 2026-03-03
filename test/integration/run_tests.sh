#!/bin/bash
# Integration test runner
# Runs all Playwright integration tests

set -e

echo "============================================"
echo "Sudoku App Integration Tests"
echo "============================================"
echo ""

# Check if server is running
echo "Checking if web server is running..."
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✓ Web server is running"
else
    echo "✗ Web server is not running!"
    echo "Please start the server with:"
    echo "  flutter build web"
    echo "  python3 -m http.server 8080 --directory build/web"
    exit 1
fi

echo ""
echo "Running integration tests..."
echo ""

# Check if Playwright is installed
if ! command -v node &> /dev/null; then
    echo "✗ Node.js is not installed!"
    exit 1
fi

# Install Playwright if needed
if [ ! -d "node_modules/playwright" ]; then
    echo "Installing Playwright..."
    npm install playwright
fi

# Run each test
TEST_FILES=(
    "basic_connectivity_test.js"
    "new_game_test.js"
    "number_input_test.js"
    "hint_test.js"
    "import_export_test.js"
    "settings_test.js"
)

PASSED=0
FAILED=0

for test_file in "${TEST_FILES[@]}"; do
    echo "Running: $test_file"
    if node "$test_file"; then
        ((PASSED++))
    else
        ((FAILED++))
        echo "✗ FAILED: $test_file"
    fi
    echo ""
done

echo "============================================"
echo "Test Results"
echo "============================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
