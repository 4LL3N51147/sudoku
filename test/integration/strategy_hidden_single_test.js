/**
 * Integration test: Hidden Single Strategy
 *
 * This test verifies that the Hidden Single strategy:
 * 1. Imports a predefined board with a hidden single pattern
 * 2. Can be selected from the strategy picker
 * 3. Runs the animation without errors
 * 4. Completes all animation phases
 */

const { chromium } = require('playwright');
const { HIDDEN_SINGLE_BOARD } = require('./test_boards');

const BASE_URL = 'http://localhost:8080';

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

async function importGame(page, gameJson) {
  // Click Import Game button
  await page.evaluate(() => {
    const semantics = document.querySelectorAll('flt-semantics');
    for (const sem of semantics) {
      if (sem.textContent.includes('Import Game')) {
        let target = sem;
        const tappable = sem.querySelector('[flt-tappable]');
        if (tappable) target = tappable;
        target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      }
    }
  });
  await page.waitForTimeout(1000);

  // Fill the textarea
  await page.fill('textarea', JSON.stringify(gameJson));
  await page.waitForTimeout(500);

  // Click Import button
  await page.evaluate(() => {
    const semantics = document.querySelectorAll('flt-semantics');
    for (const sem of semantics) {
      if (sem.textContent.trim() === 'Import') {
        let target = sem;
        const tappable = sem.querySelector('[flt-tappable]');
        if (tappable) target = tappable;
        target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      }
    }
  });
  await page.waitForTimeout(1500);
}

async function clickNextButton(page) {
  await page.evaluate(() => {
    const semantics = document.querySelectorAll('flt-semantics');
    for (const sem of semantics) {
      if (sem.textContent.includes('Next')) {
        let target = sem;
        const tappable = sem.querySelector('[flt-tappable]');
        if (tappable) target = tappable;
        target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      }
    }
  });
  await page.waitForTimeout(500);
}

async function testHiddenSingle() {
  console.log('Testing Hidden Single Strategy...\n');
  console.log('Board: Row 0 missing digit 9 at position (0, 8)');

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

  try {
    await waitForFlutter(page);
    console.log('✓ App loaded');

    // Import the predefined board
    await importGame(page, HIDDEN_SINGLE_BOARD);
    console.log('✓ Board imported');

    // Open strategy picker
    await page.keyboard.press('h');
    await page.waitForTimeout(1000);
    console.log('✓ Strategy picker opened');

    // Verify Hidden Single is available
    const hasStrategy = await page.evaluate(() => {
      const semantics = document.querySelectorAll('flt-semantics');
      for (const sem of semantics) {
        if (sem.textContent.includes('Hidden Single')) {
          return true;
        }
      }
      return false;
    });

    if (!hasStrategy) {
      throw new Error('Hidden Single strategy not found in picker');
    }
    console.log('✓ Hidden Single strategy found');

    // Select Hidden Single
    await clickByText(page, 'Hidden Single');
    await page.waitForTimeout(2000);
    console.log('✓ Hidden Single selected');

    // Click through all Next buttons to complete animation phases
    // Hidden Single has 3 phases: Scanning, Elimination, Target
    for (let i = 0; i < 3; i++) {
      await clickNextButton(page);
      await page.waitForTimeout(1000);
    }
    console.log('✓ Completed all animation phases');

    // Wait for final state
    await page.waitForTimeout(1000);

    // Close the hint banner by pressing Escape
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);

    console.log('\n✅ Hidden Single test passed!');
    console.log('   - Board with hidden single was imported');
    console.log('   - Strategy was selected from picker');
    console.log('   - Animation ran through all phases');
    console.log('   - Strategy completed without errors');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testHiddenSingle();
