// SPEC.md → Language and look: design-system colours, dark mode, answer colours
const { test, expect } = require('@playwright/test');
const { deck, card, data, open } = require('./helpers');

const oneCard = () => data([deck(1, 'Start')], [card(1, 1, 'the house', 'het huis', 1)]);
const bg = (page, sel) => page.locator(sel).evaluate((el) => getComputedStyle(el).backgroundColor);

test.describe('light mode', () => {
  test.use({ colorScheme: 'light' });

  test('uses the light palette', async ({ page }) => {
    await open(page, oneCard());
    expect(await bg(page, 'body')).toBe('rgb(234, 233, 229)');
  });

  test('Not yet is red and I know it is green', async ({ page }) => {
    await open(page, oneCard());
    await page.click('[data-go=box1]');
    expect(await bg(page, '[data-act=no]')).toBe('rgb(200, 16, 46)');
    expect(await bg(page, '[data-act=yes]')).toBe('rgb(30, 122, 60)');
    await expect(page.locator('[data-act=yes]')).toHaveCSS('color', 'rgb(255, 255, 255)');
  });
});

test.describe('dark mode', () => {
  test.use({ colorScheme: 'dark' });

  test('follows the device setting', async ({ page }) => {
    await open(page, oneCard());
    expect(await bg(page, 'body')).toBe('rgb(16, 19, 24)');
    await expect(page.locator('body')).toHaveCSS('color', 'rgb(236, 236, 230)');
  });

  test('keeps the answer colours readable with dark text', async ({ page }) => {
    await open(page, oneCard());
    await page.click('[data-go=box1]');
    expect(await bg(page, '[data-act=no]')).toBe('rgb(255, 107, 117)');
    expect(await bg(page, '[data-act=yes]')).toBe('rgb(91, 208, 138)');
    await expect(page.locator('[data-act=yes]')).toHaveCSS('color', 'rgb(20, 24, 31)');
  });

  test('the back of the card stays yellow with dark text', async ({ page }) => {
    await open(page, oneCard());
    await page.click('[data-go=box1]');
    expect(await bg(page, '.face--back')).toBe('rgb(255, 201, 23)');
    await expect(page.locator('.face--back .word')).toHaveCSS('color', 'rgb(20, 24, 31)');
  });
});

test('the browser bar colour follows the theme', async ({ page }) => {
  await open(page);
  const metas = await page.locator('meta[name="theme-color"]').evaluateAll((els) =>
    els.map((m) => `${m.media}=${m.content}`));
  expect(metas).toEqual(['(prefers-color-scheme: light)=#eae9e5', '(prefers-color-scheme: dark)=#101318']);
});

test('every colour in the CSS matches design/tokens.json, in both themes', async ({ page }) => {
  const tokens = require('../../design/tokens.json').color.tokens;
  await open(page);
  for (const theme of ['light', 'dark']) {
    await page.emulateMedia({ colorScheme: theme });
    const css = await page.evaluate((names) => {
      const st = getComputedStyle(document.documentElement);
      return Object.fromEntries(names.map((n) => [n, st.getPropertyValue('--' + n).trim().toLowerCase()]));
    }, tokens.map((t) => t.name));
    const expected = Object.fromEntries(tokens.map((t) => [t.name, t.value[theme]]));
    expect(css, `${theme} theme`).toEqual(expected);
  }
});
