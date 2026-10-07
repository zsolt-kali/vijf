// SPEC.md → All cards and Back-up screens, and the Data section
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, deckRow, toast } = require('./helpers');

const sample = () => data(
  [deck(1, 'Start'), deck(2, 'Eten')],
  [card(1, 2, 'bread', 'brood', 2), card(2, 1, 'house', 'huis', 3), card(3, 1, 'busy', 'druk', 1)],
);

test('all cards are grouped by deck, then box, and show their deck name', async ({ page }) => {
  await open(page, sample());
  await page.getByRole('button', { name: /Alles/ }).click();
  await expect(page.locator('.item .nl')).toHaveText(['druk', 'huis', 'brood']);
  await expect(page.locator('.item .nat')).toHaveText(['busy · Start', 'house · Start', 'bread · Eten']);
});

test('the × on a card deletes it', async ({ page }) => {
  await open(page, sample());
  await page.getByRole('button', { name: /Alles/ }).click();
  await page.locator('[data-del="2"]').click();
  expect((await saved(page)).cards.map((c) => c.dutch)).toEqual(['brood', 'druk']);
});

test('the all-cards back button returns to where it was opened from', async ({ page }) => {
  await open(page, sample());
  await page.getByRole('button', { name: /Alles/ }).click();
  await page.getByRole('button', { name: '← Terug' }).click();
  await expect(deckRow(page, 'Start')).toBeVisible();

  await deckRow(page, 'Eten').click();
  await page.getByRole('button', { name: /Alles/ }).click();
  await page.getByRole('button', { name: '← Terug' }).click();
  await expect(page.locator('.bar .here')).toHaveText('Eten');
});

test('the back-up text is exactly the saved data', async ({ page }) => {
  await open(page, sample());
  await page.getByRole('button', { name: /Alles/ }).click();
  await page.getByRole('button', { name: /Back-up maken/ }).click();
  const text = await page.locator('#f-json').inputValue();
  expect(JSON.parse(text)).toEqual(await saved(page));
});

async function restore(page, text) {
  await page.getByRole('button', { name: /Alles/ }).click();
  await page.getByRole('button', { name: /Back-up maken/ }).click();
  await page.fill('#f-json', text);
  await page.getByRole('button', { name: /Terugzetten/ }).click();
}

test('restoring a back-up replaces all data', async ({ page }) => {
  await open(page, sample());
  const other = data([deck(5, 'Reizen')], [card(9, 5, 'train', 'trein', 4)]);
  await restore(page, JSON.stringify(other));

  await expect(toast(page)).toHaveText('Teruggezet');
  expect(await saved(page)).toEqual(other);
  await expect(page.locator('.bar .here')).toHaveText('Reizen');
});

test('an invalid back-up is rejected and data is kept', async ({ page }) => {
  await open(page, sample());
  const before = await saved(page);
  await restore(page, '{"not": "a back-up"}');
  await expect(toast(page)).toHaveText('Ongeldige back-up');
  expect(await saved(page)).toEqual(before);

  await page.fill('#f-json', 'this is not json');
  await page.getByRole('button', { name: /Terugzetten/ }).click();
  await expect(toast(page)).toHaveText('Ongeldige back-up');
  expect(await saved(page)).toEqual(before);
});

test('wiping everything asks first and only wipes when confirmed', async ({ page }) => {
  await open(page, sample());
  await page.getByRole('button', { name: /Alles/ }).click();

  page.once('dialog', (d) => d.dismiss());
  await page.getByRole('button', { name: /Alles wissen/ }).click();
  expect((await saved(page)).cards).toHaveLength(3);

  page.once('dialog', (d) => d.accept());
  await page.getByRole('button', { name: /Alles wissen/ }).click();
  expect(await saved(page)).toEqual({ cards: [], nextId: 1, decks: [], nextDeckId: 1 });
  await expect(page.getByText('Make a deck for each topic')).toBeVisible();
});
