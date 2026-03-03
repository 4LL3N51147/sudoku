/**
 * Integration test: New game creation
 * Tests: Starting a new game at each difficulty level
 */
const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:8080';

async function testNewGame() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    console.log('Testing: New game creation');

    // Navigate to app
    await page.goto(BASE_URL);
    await page.waitForLoadState('domcontentloaded');

    // Enable accessibility
    await page.evaluate(() => {
      document.querySelector('flt-semantics-placeholder')?.click();
    });

    // Wait for main menu
    await page.waitForSelector('text=Select a difficulty to begin');
    console.log('✓ Main menu loaded');

    // Test Easy difficulty
    await page.click('button:has-text("EASY")');
    await page.waitForSelector('text=Easy'); // Difficulty label
    console.log('✓ Easy game started');

    // Go back to menu
    await page.click('button >> nth=0'); // Back button
    await page.waitForSelector('text=Select a difficulty to begin');

    // Test Medium difficulty
    await page.click('button:has-text("MEDIUM")');
    await page.waitForSelector('text=Medium');
    console.log('✓ Medium game started');

    // Go back
    await page.click('button >> nth=0');
    await page.waitForSelector('text=Select a difficulty to begin');

    // Test Hard difficulty
    await page.click('button:has-text("HARD")');
    await page.waitForSelector('text=Hard');
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
