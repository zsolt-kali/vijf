// SPEC.md → Browsing a deck
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, toast } = require('./helpers');

const added = (c, at) => Object.assign(c, { createdAt: at });
const sample = () => data([deck(1, 'Start')], [
  added(card(1, 1, 'the cheese', 'de kaas', 3), 10),
  added(card(2, 1, 'the bread', 'het brood', 1), 30),
  added(card(3, 1, 'the milk', 'de melk', 1), 20),
  added(card(4, 1, 'the strawberry', 'de aardbei', 5), 5),
]);
const front = (page) => page.locator('.face:not(.face--back) .word');
const pos = (page) => page.locator('.bar .pos');
const browse = (page) => page.getByRole('button', { name: 'Browse cards' }).click();

test('Browse cards goes through every card, box 1 first, then in the order added', async ({ page }) => {
  await open(page, sample());
  await browse(page);
  await expect(page.locator('.bar--browse .mode')).toHaveText('Browsing');
  const seen = [];
  for (let i = 1; i <= 4; i++) {
    await expect(pos(page)).toContainText(`${i} / 4`);
    seen.push(await front(page).textContent());
    if (i < 4) await page.getByRole('button', { name: 'Next →' }).click();
  }
  expect(seen).toEqual(['the milk', 'the bread', 'the cheese', 'the strawberry']);
});

test('each card shows its box, flips, and the back says to flip back', async ({ page }) => {
  await open(page, sample());
  await browse(page);
  await expect(page.locator('.face:not(.face--back) .hint--foot')).toHaveText(/Tap to flip\s*Box 1/);
  await page.click('#flip');
  await expect(page.locator('#flip')).toHaveClass(/turned/);
  await expect(page.locator('.face--back .word')).toHaveText('de melk');
  await expect(page.locator('.face--back .hint--foot')).toHaveText(/Tap to flip back\s*Box 1/);
});

test('Previous is greyed out on the first card and Next becomes Done on the last', async ({ page }) => {
  await open(page, sample());
  await browse(page);
  await expect(page.getByRole('button', { name: '← Previous' })).toBeDisabled();
  for (let i = 0; i < 3; i++) await page.getByRole('button', { name: 'Next →' }).click();
  await expect(page.getByRole('button', { name: 'Next →' })).toHaveCount(0);
  await page.getByRole('button', { name: '← Previous' }).click();
  await expect(front(page)).toHaveText('the cheese');
  await page.getByRole('button', { name: 'Next →' }).click();
  await page.getByRole('button', { name: 'Done' }).click();
  await expect(page.locator('[data-go=box1]')).toBeVisible();
});

test('the arrow keys go back and forward', async ({ page }) => {
  await open(page, sample());
  await browse(page);
  await page.keyboard.press('ArrowRight');
  await expect(front(page)).toHaveText('the bread');
  await page.keyboard.press('ArrowLeft');
  await page.keyboard.press('ArrowLeft');      // already on the first card
  await expect(front(page)).toHaveText('the milk');
});

test('browsing changes no box and no seenAt', async ({ page }) => {
  await open(page, sample());
  const before = await saved(page);
  await browse(page);
  for (let i = 0; i < 3; i++) await page.getByRole('button', { name: 'Next →' }).click();
  await page.getByRole('button', { name: 'Done' }).click();
  expect(await saved(page)).toEqual(before);
});

test('a deck without cards cannot be browsed', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], []));
  await expect(page.getByRole('button', { name: 'Browse cards' })).toBeDisabled();
});

test('the cog edits the card and returns to it', async ({ page }) => {
  await open(page, sample());
  await browse(page);
  await page.getByRole('button', { name: 'Next →' }).click();
  await page.locator('.face:not(.face--back) .cog').click();
  await page.fill('#f-edit-dutch', 'het bruine brood');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(pos(page)).toContainText('2 / 4');
  await page.click('#flip');
  await expect(page.locator('.face--back .word')).toHaveText('het bruine brood');
});

test('deleting a card while browsing shows the next one, and undo brings it back', async ({ page }) => {
  await open(page, sample());
  await browse(page);
  await page.getByRole('button', { name: 'Next →' }).click();
  await page.locator('.face:not(.face--back) .cog').click();
  await page.getByRole('button', { name: /Delete card/ }).click();
  await expect(pos(page)).toContainText('2 / 3');
  await expect(front(page)).toHaveText('the cheese');
  await page.getByRole('button', { name: 'Undo' }).click();
  await expect(toast(page)).toHaveText('Restored');
  await expect(pos(page)).toContainText('2 / 4');
  await expect(front(page)).toHaveText('the bread');
});

test('search still opens its own edit form and returns to the results', async ({ page }) => {
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'the bread', 'het brood', 1)]));
  await page.fill('#f-search', 'brood');
  await page.locator('[data-card="1"]').click();
  await expect(page.getByRole('button', { name: '← Search' })).toBeVisible();
});
