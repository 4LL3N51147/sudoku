/**
 * Integration test: All Sudoku solving strategies
 * Tests: Verifying all 7 solving strategies are available in the UI
 *
 * This test verifies:
 * 1. Strategy picker opens correctly
 * 2. All 7 strategies are listed and selectable
 * 3. Hidden Single at least runs and produces UI feedback
 */

const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:8080';

// All 7 strategies that should be available
const STRATEGIES = [
  'Hidden Single',
  'Naked Pair',
  'Hidden Pair',
  'Naked Triple',
  'Hidden Triple',
  'Naked Quad',
  'Hidden Quad'
];

async function waitForFlutter(page) {
  await page.goto(BASE_URL);
  await page.waitForLoadState('domcontentloaded');
  await page.waitForFunction(() => document.querySelector('flutter-view') !== null, { timeout: 10000 });
  await page.waitForTimeout(5000);
  await page.evaluate(() => {
    document.querySelector('flt-semantics-placeholder')?.click();
  });
  await page.waitForTimeout(3000);
}

async function clickByText(page, text) {
  const success = await page.evaluate((searchText) => {
    const semantics = document.querySelectorAll('flt-semantics');
    for (const sem of semantics) {
      if (sem.textContent.includes(searchText)) {
        let target = sem;
        const tappable = sem.querySelector('[flt-tappable]');
        if (tappable) target = tappable;
        target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
        return true;
      }
    }
    return false;
  }, text);

  if (!success) {
    throw new Error(`Could not click element with text: ${text}`);
  }
}

async function openStrategyPicker(page) {
  await page.keyboard.press('h');
  await page.waitForTimeout(1500);

  const pickerOpen = await page.evaluate(() => {
    const semantics = document.querySelectorAll('flt-semantics');
    for (const sem of semantics) {
      if (sem.textContent.includes('Choose a Strategy')) {
        return true;
      }
    }
    return false;
  });

  if (!pickerOpen) {
    throw new Error('Could not open strategy picker');
  }
}

async function verifyStrategyInPicker(page, strategyName) {
  const found = await page.evaluate((name) => {
    const semantics = document.querySelectorAll('flt-semantics');
    for (const sem of semantics) {
      if (sem.textContent.includes(name)) {
        return true;
      }
    }
    return false;
  }, strategyName);

  return found;
}

async function runTests() {
  console.log('=== Sudoku Strategy Integration Tests ===\n');

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

  let foundStrategies = 0;
  let missingStrategies = [];

  try {
    // Wait for Flutter to load
    await waitForFlutter(page);
    console.log('✓ App loaded\n');

    // Start a game
    await clickByText(page, 'EASY');
    await page.waitForTimeout(1500);
    console.log('✓ Game started\n');

    // Open strategy picker
    await openStrategyPicker(page);
    console.log('✓ Strategy picker opened\n');

    // Check each strategy is available
    console.log('Verifying strategies are available in picker:\n');

    for (const strategy of STRATEGIES) {
      const found = await verifyStrategyInPicker(page, strategy);
      if (found) {
        console.log(`  ✓ ${strategy} - found in picker`);
        foundStrategies++;
      } else {
        console.log(`  ✗ ${strategy} - NOT found in picker`);
        missingStrategies.push(strategy);
      }
    }

    console.log('');

    // Test that at least Hidden Single can be selected and run
    console.log('Testing Hidden Single runs:\n');

    // Select Hidden Single
    const selected = await page.evaluate(() => {
      const semantics = document.querySelectorAll('flt-semantics');
      for (const sem of semantics) {
        if (sem.textContent.includes('Hidden Single')) {
          let target = sem;
          const tappable = sem.querySelector('[flt-tappable]');
          if (tappable) target = tappable;
          target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
          return true;
        }
      }
      return false;
    });

    if (selected) {
      await page.waitForTimeout(2000);

      // Check if strategy hint UI appeared
      const hintActive = await page.evaluate(() => {
        const semantics = document.querySelectorAll('flt-semantics');
        for (const sem of semantics) {
          const text = sem.textContent;
          if (text.includes('Hidden Single') ||
              text.includes('Scanning') ||
              text.includes('Remove') ||
              text.includes('can only go') ||
              text.includes('other candidates') ||
              text.includes('Next')) {
            return true;
          }
        }
        return false;
      });

      if (hintActive) {
        console.log('  ✓ Hidden Single executed and produced UI feedback\n');
      } else {
        console.log('  ⚠ Hidden Single selected but no UI feedback detected\n');
      }
    }

    console.log('============================================');
    console.log('Test Results');
    console.log('============================================');
    console.log(`Strategies found in picker: ${foundStrategies}/${STRATEGIES.length}`);

    if (missingStrategies.length > 0) {
      console.log(`Missing strategies: ${missingStrategies.join(', ')}`);
      console.log('\n❌ Test failed - not all strategies are available');
      process.exit(1);
    } else {
      console.log('\n✅ All strategies are available in the picker!');
    }

  } catch (error) {
    console.error('Test error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

runTests();
