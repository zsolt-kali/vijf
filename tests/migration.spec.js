// SPEC.md → Data → Migration. These protect existing users' progress: never weaken them.
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, toast, openBackup } = require('./helpers');

// Saved data as the app wrote it before decks existed.
const v1 = () => ({
  cards: [
    { id: 1, native: 'the house', dutch: 'het huis', box: 3, createdAt: 1, reviewedAt: 2 },
    { id: 2, native: 'tomorrow', dutch: 'morgen', box: 5, createdAt: 1, reviewedAt: 2 },
    { id: 5, native: 'busy', dutch: 'druk', box: 1, createdAt: 1, reviewedAt: null },
  ],
  nextId: 6,
});

test('data from before decks moves into a Start deck, keeping every box', async ({ page }) => {
  await open(page, v1());
  const s = await saved(page);

  expect(s.decks).toEqual([{ id: 1, name: 'Start', createdAt: expect.any(Number) }]);
  expect(s.nextDeckId).toBe(2);
  expect(s.nextId).toBe(6);
  expect(s.cards.map((c) => [c.id, c.box, c.deckId])).toEqual([[1, 3, 1], [2, 5, 1], [5, 1, 1]]);
  expect(s.cards[0]).toMatchObject({ native: 'the house', dutch: 'het huis', reviewedAt: 2 });
});

test('after migrating, the app opens straight into Start with the old progress', async ({ page }) => {
  await open(page, v1());
  await expect(page.locator('.bar .here')).toHaveText('Start');
  await expect(page.locator('.tally')).toContainText('1 / 3');
  await expect(page.locator('[data-go=box3] .cnt')).toHaveText('1');
});

test('a missing nextId is rebuilt from the highest card id', async ({ page }) => {
  const old = v1();
  delete old.nextId;
  await open(page, old);
  expect((await saved(page)).nextId).toBe(6);
});

test('cards without a valid deck join an existing Start deck instead of a new one', async ({ page }) => {
  const s = data([deck(1, 'Eten'), deck(2, 'Start')], [card(1, 1, 'a', 'a')]);
  s.cards.push({ id: 7, native: 'lost', dutch: 'kwijt', box: 2, createdAt: 1, reviewedAt: null, deckId: 99 });
  await open(page, s);

  const after = await saved(page);
  expect(after.decks.map((d) => d.name)).toEqual(['Eten', 'Start']);
  expect(after.cards.find((c) => c.id === 7)).toMatchObject({ deckId: 2, box: 2 });
});

test('data already in the current shape is left unchanged', async ({ page }) => {
  const current = data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a', 4), card(2, 2, 'b', 'b', 2)]);
  await open(page, current);
  expect(await saved(page)).toEqual(current);
});

test('restoring a back-up from before decks puts its cards in Start', async ({ page }) => {
  await open(page, data([deck(1, 'Eten'), deck(2, 'Werk')], [card(1, 1, 'a', 'a')]));
  await openBackup(page);
  await page.fill('#f-json', JSON.stringify(v1()));
  await page.getByRole('button', { name: /Restore/ }).click();

  await expect(toast(page)).toHaveText('Restored');
  const s = await saved(page);
  expect(s.decks.map((d) => d.name)).toEqual(['Start']);
  expect(s.cards.map((c) => c.box)).toEqual([3, 5, 1]);
});
