// SPEC.md → Decks, and the Decks / Deck screens
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, deckRow, toast, menu } = require('./helpers');

test('a new user sees an empty deck list with the starter set button', async ({ page }) => {
  await open(page);
  await expect(page.getByText('Make a deck for each topic')).toBeVisible();
  await expect(page.getByRole('button', { name: /Load 12 starter words/ })).toBeVisible();
});

test('the starter set creates a Start deck with 12 words in box 1 and opens it', async ({ page }) => {
  await open(page);
  await page.getByRole('button', { name: /Load 12 starter words/ }).click();

  const s = await saved(page);
  expect(s.decks.map((d) => d.name)).toEqual(['Start']);
  expect(s.cards).toHaveLength(12);
  expect(s.cards.every((c) => c.box === 1 && c.deckId === s.decks[0].id)).toBe(true);
  await expect(page.locator('.bar .here')).toHaveText('Start');
});

test('a new user can create a deck right on the empty deck list', async ({ page }) => {
  await open(page);
  await page.fill('#f-deck-name', 'Eten');
  await page.getByRole('button', { name: /Create/ }).click();

  await expect(page.locator('.bar .here')).toHaveText('Eten');
  expect((await saved(page)).decks.map((d) => d.name)).toEqual(['Eten']);
});

test('pressing Enter in the name field also creates the deck', async ({ page }) => {
  await open(page);
  await page.fill('#f-deck-name', 'Werk');
  await page.press('#f-deck-name', 'Enter');
  await expect(page.locator('.bar .here')).toHaveText('Werk');
});

test('New deck in the menu opens a name field; Create saves the deck and opens it', async ({ page }) => {
  await open(page, data([deck(1, 'Eten'), deck(2, 'Werk')], []));
  await menu(page, 'New deck');
  await expect(page.locator('#f-deck-name')).toBeFocused();
  await page.fill('#f-deck-name', 'Reizen');
  await page.press('#f-deck-name', 'Enter');

  await expect(page.locator('.bar .here')).toHaveText('Reizen');
  expect((await saved(page)).decks.map((d) => d.name)).toEqual(['Eten', 'Werk', 'Reizen']);
});

test('the New deck screen has a back button to the deck list', async ({ page }) => {
  await open(page, data([deck(1, 'Eten'), deck(2, 'Werk')], []));
  await menu(page, 'New deck');
  await page.getByRole('button', { name: '← Decks' }).click();
  await expect(deckRow(page, 'Eten')).toBeVisible();
});

test('deck names cannot be empty or duplicate (case-insensitive)', async ({ page }) => {
  await open(page, data([deck(1, 'Eten'), deck(2, 'Werk')], []));
  await menu(page, 'New deck');

  await page.fill('#f-deck-name', '   ');
  await page.getByRole('button', { name: /Create/ }).click();
  await expect(toast(page)).toHaveText('Give the deck a name');

  await page.fill('#f-deck-name', ' eten ');
  await page.getByRole('button', { name: /Create/ }).click();
  await expect(toast(page)).toHaveText('That deck already exists');

  expect((await saved(page)).decks).toHaveLength(2);
});

test('the deck list header has only the wordmark and the menu button, no deck count', async ({ page }) => {
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], []));
  await expect(page.locator('.top .tally')).toHaveCount(0);
  await expect(page.locator('.top')).not.toContainText('decks');
  await expect(page.getByRole('button', { name: 'More' })).toBeVisible();
  // with decks, creating one and backing up live only in the menu
  await expect(page.locator('#f-deck-name')).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Backup' })).toHaveCount(0);
});

test('the menu holds New deck and Backup; tapping outside or Escape closes it', async ({ page }) => {
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], []));
  const more = page.getByRole('button', { name: 'More' });
  await more.click();
  await expect(page.getByRole('menuitem')).toHaveText(['New deck', 'Backup']);
  await expect(more).toHaveAttribute('aria-expanded', 'true');

  // a tap on a deck behind the menu only closes the menu
  await deckRow(page, 'Start').click();
  await expect(page.getByRole('menuitem')).toHaveCount(0);
  await expect(deckRow(page, 'Start')).toBeVisible();

  await more.click();
  await page.keyboard.press('Escape');
  await expect(page.getByRole('menuitem')).toHaveCount(0);
});

test('with several decks the app opens on the deck list', async ({ page }) => {
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], []));
  await expect(deckRow(page, 'Start')).toBeVisible();
  await expect(deckRow(page, 'Eten')).toBeVisible();
});

test('with exactly one deck the app opens straight into it', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a')]));
  await expect(page.locator('.bar .here')).toHaveText('Start');
  await expect(page.locator('[data-go=box1]')).toBeVisible();
});

test('each deck row shows its card count and learned count', async ({ page }) => {
  await open(page, data(
    [deck(1, 'Start'), deck(2, 'Eten')],
    [card(1, 1, 'a', 'a', 5), card(2, 1, 'b', 'b', 2), card(3, 1, 'c', 'c', 1), card(4, 2, 'd', 'd', 1)],
  ));
  await expect(deckRow(page, 'Start').locator('.sub')).toHaveText('3 cards');
  await expect(deckRow(page, 'Start').locator('.cnt')).toHaveText('1/3');
  await expect(deckRow(page, 'Eten').locator('.sub')).toHaveText('1 card');
  await expect(deckRow(page, 'Eten').locator('.cnt')).toHaveText('0/1');
});

test('inside a deck, boxes and tally count only that deck', async ({ page }) => {
  await open(page, data(
    [deck(1, 'Start'), deck(2, 'Eten')],
    [card(1, 1, 'a', 'a', 5), card(2, 1, 'b', 'b', 1), card(3, 2, 'c', 'c', 5), card(4, 2, 'd', 'd', 5)],
  ));
  await deckRow(page, 'Start').click();
  await expect(page.locator('.tally')).toContainText('1 / 2');
  await expect(page.locator('[data-go=box5] .cnt')).toHaveText('1');
  await expect(page.locator('[data-go=box1] .cnt')).toHaveText('1');
});

test('the back button on a deck returns to the deck list', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], []));
  await page.getByRole('button', { name: '← Decks' }).click();
  await expect(deckRow(page, 'Start')).toBeVisible();
});

test('the study breadcrumb links to the deck list and to the deck', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1)]));

  await page.click('[data-go=box1]');
  await page.locator('.crumbs').getByRole('button', { name: 'Start' }).click();
  await expect(page.locator('[data-go=box1]')).toBeVisible();

  await page.click('[data-go=box1]');
  await page.locator('.crumbs').getByRole('button', { name: 'Decks' }).click();
  await expect(deckRow(page, 'Start')).toBeVisible();
});
