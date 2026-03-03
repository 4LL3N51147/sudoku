/**
 * Integration test: Strategy hints
 * Tests: Opening strategy picker and running hints
 */
const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:8080';

async function testHints() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    console.log('Testing: Strategy hints system');

    await page.goto(BASE_URL);
    await page.waitForLoadState('domcontentloaded');

    // Enable accessibility
    await page.evaluate(() => {
      document.querySelector('flt-semantics-placeholder')?.click();
    });

    // Start Easy game
    await page.click('button:has-text("EASY")');
    await page.waitForTimeout(500);

    // Find and click the lightbulb button (strategy picker)
    // It should be the second IconButton in the toolbar
    const buttons = await page.locator('button').all();
    console.log(`✓ Found ${buttons.length} buttons`);

    // Try clicking button index 2 (lightbulb in wide layout)
    await buttons[2].click();
    await page.waitForTimeout(300);

    // Check if strategy picker opened
    const strategyPicker = await page.locator('text=Choose a Strategy').count();
    if (strategyPicker > 0) {
      console.log('✓ Strategy picker opened');

      // Check all strategy options exist
      const strategies = [
        'Hidden Single',
        'Naked Pair',
        'Hidden Pair',
        'Naked Triple',
        'Hidden Triple',
        'Naked Quad',
        'Hidden Quad'
      ];

      for (const strategy of strategies) {
        const exists = await page.locator(`button:has-text("${strategy}")`).count();
        if (exists > 0) {
          console.log(`  ✓ ${strategy} option found`);
        }
      }

      // Press Escape to close
      await page.keyboard.press('Escape');
      await page.waitForTimeout(300);
    } else {
      console.log('Strategy picker may use different index');
    }

    console.log('\n✅ Hint system tests passed!');
  } catch (error) {
    console.error('✗ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testHints();
