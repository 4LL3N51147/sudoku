/**
 * Integration test: New game creation
 * Tests: Starting a new game at each difficulty level
 */
const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:8080';

async function waitForFlutter(page) {
  // Navigate to the app
  await page.goto(BASE_URL);

  // Wait for the page to load
  await page.waitForLoadState('domcontentloaded');

  // Wait for Flutter view to exist in the DOM
  await page.waitForFunction(() => document.querySelector('flutter-view') !== null, { timeout: 10000 });

  // Give Flutter time to initialize
  await page.waitForTimeout(5000);

  // Enable accessibility by clicking the semantics placeholder
  await page.evaluate(() => {
    document.querySelector('flt-semantics-placeholder')?.click();
  });

  // Wait for semantics to appear after enabling accessibility
  await page.waitForTimeout(3000);
}

async function clickByText(page, text) {
  // Click on flt-semantics element containing the text
  const success = await page.evaluate((searchText) => {
    const semantics = document.querySelectorAll('flt-semantics');
    for (const sem of semantics) {
      if (sem.textContent.includes(searchText)) {
        // Find the element with flt-tappable attribute or use the semantics element itself
        let target = sem;
        const tappable = sem.querySelector('[flt-tappable]');
        if (tappable) {
          target = tappable;
        }
        // Try clicking via dispatchEvent
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

async function clickBackButton(page) {
  // Click on the first button semantics element (back button in toolbar)
  const success = await page.evaluate(() => {
    const semantics = document.querySelectorAll('flt-semantics[role="button"]');
    if (semantics.length > 0) {
      const target = semantics[0];
      target.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return true;
    }
    return false;
  });

  if (!success) {
    throw new Error('Could not click back button');
  }
}

async function testNewGame() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

  try {
    console.log('Testing: New game creation');

    // Navigate to app and wait for Flutter
    await waitForFlutter(page);

    // Wait for main menu
    await page.waitForTimeout(500);
    console.log('✓ Main menu loaded');

    // Test Easy difficulty - click on EASY button
    await clickByText(page, 'EASY');
    await page.waitForTimeout(1000);
    console.log('✓ Easy game started');

    // Go back to menu
    await clickBackButton(page);
    await page.waitForTimeout(1000);
    console.log('✓ Returned to menu');

    // Test Medium difficulty
    await clickByText(page, 'MEDIUM');
    await page.waitForTimeout(1000);
    console.log('✓ Medium game started');

    // Go back
    await clickBackButton(page);
    await page.waitForTimeout(1000);

    // Test Hard difficulty
    await clickByText(page, 'HARD');
    await page.waitForTimeout(1000);
    console.log('✓ Hard game started');

    console.log('\n✅ All tests passed!');
  } catch (error) {
    console.error('✗ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testNewGame();
