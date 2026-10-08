// SPEC.md → Decks → Deleting and Undo
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, deckRow, openBackup, swipeLeft } = require('./helpers');

const threeDecks = () => data(
  [deck(1, 'Start'), deck(2, 'Eten'), deck(3, 'Werk')],
  [card(1, 1, 'the house', 'het huis', 3), card(2, 2, 'bread', 'brood', 4),
    card(3, 2, 'cheese', 'kaas', 2), card(4, 3, 'desk', 'bureau', 1)],
);
const swipeRow = (page, name) => deckRow(page, name).locator('xpath=..');
const undoToast = (page) => page.locator('.toast--undo');

test('swiping a deck left reveals a red delete button', async ({ page }) => {
  await open(page, threeDecks());
  await expect(swipeRow(page, 'Eten')).not.toHaveClass(/open/);

  await swipeLeft(page, deckRow(page, 'Eten'));
  await expect(swipeRow(page, 'Eten')).toHaveClass(/open/);
  await expect(page.locator('[data-del-deck="2"]')).toBeVisible();
  await expect(page.locator('[data-del-deck="2"]')).toHaveCSS('background-color', 'rgb(200, 16, 46)');
  // the swipe itself does not open the deck
  await expect(deckRow(page, 'Start')).toBeVisible();
});

test('tapping delete removes the deck and all its cards', async ({ page }) => {
  await open(page, threeDecks());
  await swipeLeft(page, deckRow(page, 'Eten'));
  await page.locator('[data-del-deck="2"]').click();

  const s = await saved(page);
  expect(s.decks.map((d) => d.name)).toEqual(['Start', 'Werk']);
  expect(s.cards.map((c) => c.dutch)).toEqual(['het huis', 'bureau']);
  await expect(deckRow(page, 'Eten')).toHaveCount(0);
});

test('a short swipe springs back', async ({ page }) => {
  await open(page, threeDecks());
  await swipeLeft(page, deckRow(page, 'Eten'), 30);
  await expect(swipeRow(page, 'Eten')).not.toHaveClass(/open/);
});

test('tapping elsewhere closes an open row without opening a deck', async ({ page }) => {
  await open(page, threeDecks());
  await swipeLeft(page, deckRow(page, 'Eten'));
  await deckRow(page, 'Start').click();

  await expect(swipeRow(page, 'Eten')).not.toHaveClass(/open/);
  await expect(deckRow(page, 'Start')).toBeVisible();
});

test('undo restores the deck in its place with its cards and boxes', async ({ page }) => {
  await open(page, threeDecks());
  await swipeLeft(page, deckRow(page, 'Eten'));
  await page.locator('[data-del-deck="2"]').click();
  await undoToast(page).getByRole('button', { name: 'Undo' }).click();

  const s = await saved(page);
  expect(s.decks.map((d) => d.name)).toEqual(['Start', 'Eten', 'Werk']);
  expect(s.cards.filter((c) => c.deckId === 2).map((c) => `${c.dutch}:${c.box}`).sort())
    .toEqual(['brood:4', 'kaas:2']);
  await expect(page.locator('.slot--deck .lbl')).toHaveText(['Start', 'Eten', 'Werk']);
  await expect(undoToast(page)).toHaveCount(0);
});

test('the undo toast disappears after 5 seconds and the delete stays', async ({ page }) => {
  await page.clock.install();
  await open(page, threeDecks());
  await swipeLeft(page, deckRow(page, 'Eten'));
  await page.locator('[data-del-deck="2"]').click();

  await page.clock.runFor(4000);
  await expect(undoToast(page)).toBeVisible();
  await page.clock.runFor(1500);
  await expect(undoToast(page)).toHaveCount(0);
  expect((await saved(page)).decks).toHaveLength(2);
});

test('a second delete replaces the undo; only the latest can be undone', async ({ page }) => {
  await open(page, threeDecks());
  await swipeLeft(page, deckRow(page, 'Eten'));
  await page.locator('[data-del-deck="2"]').click();
  await swipeLeft(page, deckRow(page, 'Werk'));
  await page.locator('[data-del-deck="3"]').click();

  await expect(undoToast(page)).toHaveCount(1);
  await undoToast(page).getByRole('button', { name: 'Undo' }).click();
  expect((await saved(page)).decks.map((d) => d.name)).toEqual(['Start', 'Werk']);
});

test('restoring a back-up cancels a pending undo', async ({ page }) => {
  await open(page, threeDecks());
  await swipeLeft(page, deckRow(page, 'Eten'));
  await page.locator('[data-del-deck="2"]').click();

  await openBackup(page);
  await page.fill('#f-json', JSON.stringify(data([deck(1, 'Reizen')], [])));
  await page.getByRole('button', { name: /Restore/ }).click();
  await expect(undoToast(page)).toHaveCount(0);
});

test('deleting the last deck shows the empty deck list', async ({ page }) => {
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a')]));
  for (const name of ['Start', 'Eten']) {
    await swipeLeft(page, deckRow(page, name));
    await page.locator('.swipe.open .swipe__del').click();
  }
  await expect(page.getByText('Make a deck for each topic')).toBeVisible();
  await expect(page.getByRole('button', { name: /Load 12 starter words/ })).toBeVisible();
});
