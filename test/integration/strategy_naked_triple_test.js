/**
 * Integration test: Naked Triple Strategy
 */

const { chromium } = require('playwright');
const { NAKED_TRIPLE_BOARD } = require('./test_boards');

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

  await page.fill('textarea', JSON.stringify(gameJson));
  await page.waitForTimeout(500);

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

async function testNakedTriple() {
  console.log('Testing Naked Triple Strategy...\n');
  console.log('Board: Row 0 has three cells forming naked triple');

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

  try {
    await waitForFlutter(page);
    console.log('✓ App loaded');

    await importGame(page, NAKED_TRIPLE_BOARD);
    console.log('✓ Board imported');

    await page.keyboard.press('h');
    await page.waitForTimeout(1000);
    console.log('✓ Strategy picker opened');

    const hasStrategy = await page.evaluate(() => {
      const semantics = document.querySelectorAll('flt-semantics');
      for (const sem of semantics) {
        if (sem.textContent.includes('Naked Triple')) {
          return true;
        }
      }
      return false;
    });

    if (!hasStrategy) {
      throw new Error('Naked Triple strategy not found in picker');
    }
    console.log('✓ Naked Triple strategy found');

    await clickByText(page, 'Naked Triple');
    await page.waitForTimeout(2000);
    console.log('✓ Naked Triple selected');

    // Naked Triple has 4 phases: Scan, Pattern, Elimination, Target
    for (let i = 0; i < 3; i++) {
      await clickNextButton(page);
      await page.waitForTimeout(1000);
    }
    console.log('✓ Completed all animation phases');

    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);

    console.log('\n✅ Naked Triple test passed!');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testNakedTriple();
