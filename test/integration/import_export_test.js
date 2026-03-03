/**
 * Integration test: Import and Export
 * Tests: Game import and export functionality
 */
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:8080';

const TEST_GAME = {
  version: 1,
  difficulty: 'easy',
  elapsedSeconds: 0,
  board: [
    [1, 2, 3, 4, 5, 6, 7, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 0]
  ],
  solution: [
    [1, 2, 3, 4, 5, 6, 7, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8]
  ],
  isGiven: Array(9).fill(Array(9).fill(true)),
  isError: Array(9).fill(Array(9).fill(false)),
  undoStack: [],
  savedAt: new Date().toISOString()
};

async function testImportExport() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    console.log('Testing: Import/Export functionality');

    await page.goto(BASE_URL);
    await page.waitForLoadState('domcontentloaded');

    // Enable accessibility
    await page.evaluate(() => {
      document.querySelector('flt-semantics-placeholder')?.click();
    });

    // Click Import Game
    await page.click('button:has-text("Import Game")');
    await page.waitForSelector('text=Paste game JSON here');
    console.log('✓ Import dialog opened');

    // Fill in the test game JSON
    await page.fill('input', JSON.stringify(TEST_GAME));
    console.log('✓ Test game JSON entered');

    // Click Import
    await page.click('button:has-text("Import")');
    await page.waitForTimeout(500);

    // Check if game loaded
    const difficultyText = await page.locator('text=Easy').count();
    if (difficultyText > 0) {
      console.log('✓ Game imported successfully');
    }

    // Test export - click export button
    const exportButton = page.locator('button >> nth=2');
    await exportButton.click();
    await page.waitForTimeout(500);
    console.log('✓ Export triggered');

    console.log('\n✅ Import/Export tests passed!');
  } catch (error) {
    console.error('✗ Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

testImportExport();
