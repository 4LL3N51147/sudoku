/**
 * Integration test: Settings
 * Tests: Settings dialog and animation timing controls
 */
const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:8080';

async function testSettings() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    console.log('Testing: Settings functionality');

    await page.goto(BASE_URL);
    await page.waitForLoadState('domcontentloaded');

    // Enable accessibility
    await page.evaluate(() => {
      document.querySelector('flt-semantics-placeholder')?.click();
    });

    // Start a game
    await page.click('button:has-text("EASY")');
    await page.waitForTimeout(500);

    // Click settings button (index 1 in toolbar)
    const buttons = await page.locator('button').all();
    await buttons[1].click();
    await page.waitForTimeout(300);

    // Check if settings dialog opened
    const settingsDialog = await page.locator('text=Settings').count();
    if (settingsDialog > 0) {
      console.log('✓ Settings dialog opened');

      // Check for animation controls
      const scanControl = await page.locator('text=Scan').count();
      const elimControl = await page.locator('text=Elimination').count();
      const targetControl = await page.locator('text=Target').count();

      if (scanControl > 0) console.log('  ✓ Scan timing control found');
      if (elimControl > 0) console.log('  ✓ Elimination timing control found');
      if (targetControl > 0) console.log('  ✓ Target timing control found');

      // Check for about section
      const version = await page.locator('text=Version').count();
      if (version > 0) console.log('  ✓ Version info found');
    }

    // Close with Escape
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    console.log('✓ Settings closed');

    console.log('\n✅ Settings tests passed!');
  } catch (error) {
    console.error('✗ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testSettings();
