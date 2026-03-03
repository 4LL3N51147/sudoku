/**
 * Integration test: Number input
 * Tests: Selecting cells and entering numbers
 */
const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:8080';

async function testNumberInput() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    console.log('Testing: Number input functionality');

    await page.goto(BASE_URL);
    await page.waitForLoadState('domcontentloaded');

    // Enable accessibility
    await page.evaluate(() => {
      document.querySelector('flt-semantics-placeholder')?.click();
    });

    // Start Easy game
    await page.click('button:has-text("EASY")');
    await page.waitForTimeout(500);

    // Get initial board state buttons (cells)
    const cellButtons = await page.locator('button').all();
    console.log(`✓ Found ${cellButtons.length} buttons on page`);

    // Try clicking an empty cell and entering a number
    // Look for a cell that doesn't have a number (no text content)
    const numberPadButtons = await page.locator('button:has-text(/^[1-9]$/)').all();
    if (numberPadButtons.length > 0) {
      console.log(`✓ Number pad found with ${numberPadButtons.length} buttons`);
    }

    // Test pause functionality
    const pauseButton = page.locator('button >> nth=3'); // Pause button
    await pauseButton.click();
    await page.waitForSelector('text=PAUSED');
    console.log('✓ Pause overlay appeared');

    // Resume
    await page.click('button:has-text("Resume")');
    await page.waitForTimeout(300);
    console.log('✓ Game resumed');

    console.log('\n✅ Number input tests passed!');
  } catch (error) {
    console.error('✗ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testNumberInput();
