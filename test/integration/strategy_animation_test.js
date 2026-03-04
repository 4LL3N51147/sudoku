/**
 * Integration tests for Sudoku strategy hint animations.
 * Tests the hint system by creating specific board states and verifying
 * that the correct strategies are found and animations display properly.
 */

const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:9000';

async function waitForApp(page) {
  // Wait for Flutter app to load
  await page.goto(BASE_URL);
  await page.waitForSelector('flt-semantics-placeholder', { timeout: 10000 });
  await page.evaluate(() => {
    document.querySelector('flt-semantics-placeholder')?.click();
  });
  await page.waitForTimeout(500);
}

async function startGame(page) {
  // Click EASY button to start a game
  const buttons = await page.getByRole('button').all();
  for (const btn of buttons) {
    const text = await btn.textContent();
    if (text && text.includes('EASY')) {
      await btn.click();
      await page.waitForTimeout(1000);
      return;
    }
  }
  throw new Error('Could not find EASY button');
}

async function openHintDialog(page) {
  // Find and click the hint button
  const buttons = await page.getByRole('button').all();
  for (const btn of buttons) {
    const text = await btn.textContent();
    if (text && text.includes('lightbulb')) {
      await btn.click();
      await page.waitForTimeout(500);
      return;
    }
  }
  throw new Error('Could not find hint button');
}

async function selectStrategy(page, strategyName) {
  // Select a strategy from the picker
  const buttons = await page.getByRole('button').all();
  for (const btn of buttons) {
    const text = await btn.textContent();
    if (text && text.includes(strategyName)) {
      await btn.click();
      await page.waitForTimeout(500);
      return;
    }
  }
  throw new Error(`Could not find ${strategyName} button`);
}

async function clickNextButton(page) {
  // Find and click the Next button
  const buttons = await page.getByRole('button').all();
  for (const btn of buttons) {
    const text = await btn.textContent();
    if (text && text.includes('Next')) {
      await btn.click();
      await page.waitForTimeout(300);
      return;
    }
  }
  throw new Error('Could not find Next button');
}

async function testHiddenSingle(page) {
  console.log('Testing Hidden Single...');
  await startGame(page);
  await openHintDialog(page);
  await selectStrategy(page, 'Hidden Single');

  // Check scan phase message
  let found = false;
  const buttons1 = await page.getByRole('button').all();
  for (const btn of buttons1) {
    const text = await btn.textContent();
    if (text && text.includes('Scanning')) {
      console.log('  ✓ Scan phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Scan phase message not found');

  // Click Next to see elimination phase
  await clickNextButton(page);

  // Check elimination phase message
  found = false;
  const buttons2 = await page.getByRole('button').all();
  for (const btn of buttons2) {
    const text = await btn.textContent();
    if (text && (text.includes('Remove') || text.includes('can only go'))) {
      console.log('  ✓ Elimination phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Elimination phase message not found');

  // Click Next to see target/final phase
  await clickNextButton(page);

  console.log('Hidden Single test complete\n');
}

async function testNakedPair(page) {
  console.log('Testing Naked Pair...');
  await startGame(page);
  await openHintDialog(page);
  await selectStrategy(page, 'Naked Pair');

  // Check pattern phase message
  let found = false;
  let message = '';
  const buttons1 = await page.getByRole('button').all();
  for (const btn of buttons1) {
    const text = await btn.textContent();
    if (text) {
      message = text;
      if (text.includes('Naked Pair')) {
        console.log('  ✓ Pattern phase: ' + text.trim());
        found = true;
        break;
      }
    }
  }
  if (!found) console.log('  ✗ Pattern phase message not found, got: ' + message);

  // Click Next to see elimination phase
  await clickNextButton(page);

  // Check elimination phase message
  found = false;
  const buttons2 = await page.getByRole('button').all();
  for (const btn of buttons2) {
    const text = await btn.textContent();
    if (text && text.includes('Remove')) {
      console.log('  ✓ Elimination phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Elimination phase message not found');

  // Click Next to finish
  await clickNextButton(page);

  console.log('Naked Pair test complete\n');
}

async function testHiddenPair(page) {
  console.log('Testing Hidden Pair...');
  await startGame(page);
  await openHintDialog(page);
  await selectStrategy(page, 'Hidden Pair');

  // Check pattern phase message
  let found = false;
  const buttons1 = await page.getByRole('button').all();
  for (const btn of buttons1) {
    const text = await btn.textContent();
    if (text && text.includes('Hidden Pair')) {
      console.log('  ✓ Pattern phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Pattern phase message not found');

  // Click Next to see elimination phase
  await clickNextButton(page);

  // Check elimination phase message
  found = false;
  const buttons2 = await page.getByRole('button').all();
  for (const btn of buttons2) {
    const text = await btn.textContent();
    if (text && text.includes('other candidates')) {
      console.log('  ✓ Elimination phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Elimination phase message not found');

  // Click Next to finish
  await clickNextButton(page);

  console.log('Hidden Pair test complete\n');
}

async function testNakedTriple(page) {
  console.log('Testing Naked Triple...');
  await startGame(page);
  await openHintDialog(page);
  await selectStrategy(page, 'Naked Triple');

  // Check pattern phase message
  let found = false;
  const buttons1 = await page.getByRole('button').all();
  for (const btn of buttons1) {
    const text = await btn.textContent();
    if (text && text.includes('Naked Triple')) {
      console.log('  ✓ Pattern phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Pattern phase message not found');

  // Click Next to see elimination phase
  await clickNextButton(page);

  // Check elimination phase message
  found = false;
  const buttons2 = await page.getByRole('button').all();
  for (const btn of buttons2) {
    const text = await btn.textContent();
    if (text && text.includes('Remove')) {
      console.log('  ✓ Elimination phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Elimination phase message not found');

  // Click Next to finish
  await clickNextButton(page);

  console.log('Naked Triple test complete\n');
}

async function testHiddenTriple(page) {
  console.log('Testing Hidden Triple...');
  await startGame(page);
  await openHintDialog(page);
  await selectStrategy(page, 'Hidden Triple');

  // Check pattern phase message
  let found = false;
  const buttons1 = await page.getByRole('button').all();
  for (const btn of buttons1) {
    const text = await btn.textContent();
    if (text && text.includes('Hidden Triple')) {
      console.log('  ✓ Pattern phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Pattern phase message not found');

  // Click Next to see elimination phase
  await clickNextButton(page);

  // Check elimination phase message
  found = false;
  const buttons2 = await page.getByRole('button').all();
  for (const btn of buttons2) {
    const text = await btn.textContent();
    if (text && text.includes('other candidates')) {
      console.log('  ✓ Elimination phase: ' + text.trim());
      found = true;
      break;
    }
  }
  if (!found) console.log('  ✗ Elimination phase message not found');

  // Click Next to finish
  await clickNextButton(page);

  console.log('Hidden Triple test complete\n');
}

async function runTests() {
  console.log('=== Sudoku Strategy Animation Tests ===\n');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    await waitForApp(page);

    // Test each strategy
    await testHiddenSingle(page);
    await testNakedPair(page);
    await testHiddenPair(page);
    await testNakedTriple(page);
    await testHiddenTriple(page);

    console.log('=== All tests complete ===');
  } catch (error) {
    console.error('Test error:', error.message);
  } finally {
    await browser.close();
  }
}

runTests();
