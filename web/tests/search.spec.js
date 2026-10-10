// SPEC.md → Search
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, deckRow, toast } = require('./helpers');

const sample = () => data(
  [deck(1, 'Food'), deck(2, 'Work'), deck(3, 'Travel')],
  [
    card(1, 1, 'the bread', 'het brood', 3),
    card(2, 2, 'to break', 'breken', 1),
    card(3, 3, 'wide', 'breed', 5),
    card(4, 1, 'coffee', 'café', 2),
    card(5, 2, 'busy', 'druk', 1),
  ],
);
const hits = (page) => page.locator('.slot--hit');
const search = (page, text) => page.fill('#f-search', text);

test('the search field is always on the deck list', async ({ page }) => {
  await open(page, sample());
  await expect(page.getByRole('searchbox', { name: 'Search all cards' })).toBeVisible();
  await expect(page.locator('#f-search')).toHaveAttribute('placeholder', 'Search all cards');
});

test('typing shows matching cards from every deck instead of the decks', async ({ page }) => {
  await open(page, sample());
  await search(page, 'bre');

  await expect(page.locator('.slot--deck')).toHaveCount(0);
  await expect(page.locator('.found')).toHaveText('3 cards');
  await expect(hits(page).locator('.lbl')).toHaveText(['the bread', 'to break', 'wide']);
  await expect(hits(page).nth(0).locator('.nl')).toHaveText('het brood · Food');
  await expect(hits(page).nth(2).locator('.bx')).toHaveText('5');
  // the field keeps focus while the results change
  await expect(page.locator('#f-search')).toBeFocused();
});

test('search matches either side, ignoring case and accents', async ({ page }) => {
  await open(page, sample());
  await search(page, 'DRUK');
  await expect(hits(page).locator('.lbl')).toHaveText(['busy']);
  await search(page, 'cafe');
  await expect(hits(page).locator('.lbl')).toHaveText(['coffee']);
  await search(page, 'Café');
  await expect(hits(page).locator('.lbl')).toHaveText(['coffee']);
});

test('the matching part is marked on the side it was found', async ({ page }) => {
  await open(page, sample());
  await search(page, 'cafe');
  await expect(hits(page).locator('mark')).toHaveText(['café']);
  await search(page, 'brood');
  await expect(hits(page).locator('.lbl mark')).toHaveCount(0);
  await expect(hits(page).locator('.nl mark')).toHaveText(['brood']);
});

test('no match says so', async ({ page }) => {
  await open(page, sample());
  await search(page, 'xyz');
  await expect(page.locator('.found')).toHaveText('No cards match');
  await expect(hits(page)).toHaveCount(0);
});

test('one match is "1 card"', async ({ page }) => {
  await open(page, sample());
  await search(page, 'wide');
  await expect(page.locator('.found')).toHaveText('1 card');
});

test('clearing the search brings the decks back', async ({ page }) => {
  await open(page, sample());
  await search(page, 'bre');
  await page.getByRole('button', { name: 'Clear search' }).click();
  await expect(page.locator('#f-search')).toHaveValue('');
  await expect(deckRow(page, 'Food')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Clear search' })).toBeHidden();

  await search(page, 'bre');
  await search(page, '   ');
  await expect(deckRow(page, 'Food')).toBeVisible();
});

test('tapping a result opens its edit form; Save returns to the results', async ({ page }) => {
  await open(page, sample());
  await search(page, 'bre');
  await hits(page).filter({ hasText: 'to break' }).click();
  await expect(page.locator('#f-edit-native')).toHaveValue('to break');
  await expect(page.locator('#f-edit-dutch')).toHaveValue('breken');

  await page.fill('#f-edit-native', 'to break (something)');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(toast(page)).toHaveText('Saved');
  await expect(page.locator('#f-search')).toHaveValue('bre');
  await expect(hits(page).nth(1).locator('.lbl')).toHaveText('to break (something)');

  const c = (await saved(page)).cards.find((x) => x.id === 2);
  expect(c).toMatchObject({ native: 'to break (something)', dutch: 'breken', box: 1, deckId: 2 });
});

test('Cancel and the back button return to the results unchanged', async ({ page }) => {
  await open(page, sample());
  await search(page, 'bre');
  await hits(page).first().click();
  await page.fill('#f-edit-native', 'changed');
  await page.getByRole('button', { name: 'Cancel' }).click();
  await expect(hits(page)).toHaveCount(3);

  await hits(page).first().click();
  await page.getByRole('button', { name: '← Search' }).click();
  await expect(hits(page).first().locator('.lbl')).toHaveText('the bread');
});

test('an empty field is not saved', async ({ page }) => {
  await open(page, sample());
  await search(page, 'wide');
  await hits(page).click();
  await page.fill('#f-edit-dutch', ' ');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(toast(page)).toHaveText('Fill in both fields');
  expect((await saved(page)).cards.find((x) => x.id === 3).dutch).toBe('breed');
});

test('deleting a result can be undone', async ({ page }) => {
  await open(page, sample());
  await search(page, 'bre');
  await hits(page).filter({ hasText: 'wide' }).click();
  await page.getByRole('button', { name: 'Delete card' }).click();

  await expect(hits(page)).toHaveCount(2);
  expect((await saved(page)).cards.map((c) => c.id)).toEqual([1, 2, 4, 5]);

  await page.locator('.toast--undo button').click();
  await expect(hits(page)).toHaveCount(3);
  expect((await saved(page)).cards.find((c) => c.id === 3)).toMatchObject({ dutch: 'breed', box: 5 });
});

test('opening a deck clears the search', async ({ page }) => {
  await open(page, sample());
  await search(page, 'xyz');
  await page.getByRole('button', { name: 'Clear search' }).click();
  await deckRow(page, 'Work').click();
  await page.getByRole('button', { name: '← Decks' }).click();
  await expect(page.locator('#f-search')).toHaveValue('');
});

test('search text is shown escaped, never as markup', async ({ page }) => {
  await open(page, data([deck(1, 'Food'), deck(2, 'Work')], [card(1, 1, '<b>x</b>', 'a & b', 1)]));
  await search(page, '<b');
  await expect(hits(page).locator('.lbl')).toHaveText('<b>x</b>');
  await search(page, '&');
  await expect(hits(page).locator('.nl mark')).toHaveText('&');
});
