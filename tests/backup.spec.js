// SPEC.md → Back-up screen and the Data section
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, deckRow, toast, openBackup } = require('./helpers');

const sample = () => data(
  [deck(1, 'Start'), deck(2, 'Eten')],
  [card(1, 2, 'bread', 'brood', 2), card(2, 1, 'house', 'huis', 3), card(3, 1, 'busy', 'druk', 1)],
);

test('the Back-up button is on the deck list even with no cards', async ({ page }) => {
  await open(page);
  await expect(page.getByRole('button', { name: /^Back-up/ })).toBeVisible();
});

test('there is no all-cards screen and no delete-everything button', async ({ page }) => {
  await open(page, sample());
  await expect(page.getByRole('button', { name: /^Alles/ })).toHaveCount(0);
  await deckRow(page, 'Start').click();
  await expect(page.getByRole('button', { name: /^Alles/ })).toHaveCount(0);
  await page.getByRole('button', { name: '← Stapels' }).click();
  await openBackup(page);
  await expect(page.getByRole('button', { name: /Alles wissen/ })).toHaveCount(0);
});

test('the back-up text is exactly the saved data', async ({ page }) => {
  await open(page, sample());
  await openBackup(page);
  const text = await page.locator('#f-json').inputValue();
  expect(JSON.parse(text)).toEqual(await saved(page));
});

test('the back button returns to the deck list', async ({ page }) => {
  await open(page, sample());
  await openBackup(page);
  await page.getByRole('button', { name: '← Stapels' }).click();
  await expect(deckRow(page, 'Start')).toBeVisible();
});

async function restore(page, text) {
  await openBackup(page);
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

test('a back-up can be restored onto an empty app', async ({ page }) => {
  await open(page);
  await restore(page, JSON.stringify(sample()));
  expect(await saved(page)).toEqual(sample());
  await expect(deckRow(page, 'Eten')).toBeVisible();
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
