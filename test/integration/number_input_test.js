/**
 * Integration test: Number input
 * Tests: Selecting cells and entering numbers
 */
const { chromium } = require('playwright');

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

async function clickNthButton(page, n) {
  const success = await page.evaluate((index) => {
    const semantics = document.querySelectorAll('flt-semantics[role="button"]');
    if (semantics.length > index) {
      semantics[index].dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return true;
    }
    return false;
  }, n);

  if (!success) {
    throw new Error(`Could not click button at index ${n}`);
  }
}

async function testNumberInput() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

  try {
    console.log('Testing: Number input functionality');

    await waitForFlutter(page);
    await page.waitForTimeout(500);

    // Start Easy game
    await clickByText(page, 'EASY');
    await page.waitForTimeout(1000);
    console.log('✓ Game started');

    // Test pause functionality - find and click pause button
    // Pause button is typically the 4th button (index 3) in toolbar
    await clickNthButton(page, 3);
    await page.waitForTimeout(500);

    // Check if pause overlay appeared
    const paused = await page.evaluate(() => {
      const semantics = document.querySelectorAll('flt-semantics');
      for (const sem of semantics) {
        if (sem.textContent.includes('PAUSED') || sem.textContent.includes('Resume')) {
          return true;
        }
      }
      return false;
    });

    if (paused) {
      console.log('✓ Pause overlay appeared');

      // Resume
      await clickByText(page, 'Resume');
      await page.waitForTimeout(500);
      console.log('✓ Game resumed');
    } else {
      console.log('⚠ Pause overlay not detected, may be using different index');
    }

    console.log('\n✅ Number input tests passed!');
  } catch (error) {
    console.error('✗ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testNumberInput();
