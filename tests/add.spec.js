// SPEC.md → Add screen and Bulk import format
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, deckRow, toast } = require('./helpers');

const twoDecks = () => data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a')]);

async function openAdd(page, deckName) {
  await open(page, twoDecks());
  await deckRow(page, deckName).click();
  await page.getByRole('button', { name: /Woord toevoegen/ }).click();
}

test('the deck picker defaults to the deck the user came from', async ({ page }) => {
  await openAdd(page, 'Eten');
  await expect(page.locator('#f-deck option:checked')).toHaveText('Eten');
});

test('adding one word saves it to box 1 of the chosen deck and clears the form', async ({ page }) => {
  await openAdd(page, 'Eten');
  await page.fill('#f-native', 'bread');
  await page.fill('#f-dutch', 'brood');
  await page.getByRole('button', { name: /Bewaren in doos 1/ }).click();

  await expect(toast(page)).toHaveText('Toegevoegd aan doos 1');
  await expect(page.locator('#f-native')).toHaveValue('');
  await expect(page.locator('#f-dutch')).toHaveValue('');
  await expect(page.locator('#f-native')).toBeFocused();
  const added = (await saved(page)).cards.find((c) => c.dutch === 'brood');
  expect(added).toMatchObject({ native: 'bread', deckId: 2, box: 1 });
});

test('both fields are required', async ({ page }) => {
  await openAdd(page, 'Eten');
  await page.fill('#f-native', 'bread');
  await page.getByRole('button', { name: /Bewaren in doos 1/ }).click();
  await expect(toast(page)).toHaveText('Vul beide velden in');
  expect((await saved(page)).cards).toHaveLength(1);
});

test('picking another deck adds there and makes it the current deck', async ({ page }) => {
  await openAdd(page, 'Eten');
  await page.selectOption('#f-deck', { label: 'Start' });
  await page.fill('#f-native', 'house');
  await page.fill('#f-dutch', 'huis');
  await page.getByRole('button', { name: /Bewaren in doos 1/ }).click();

  expect((await saved(page)).cards.find((c) => c.dutch === 'huis').deckId).toBe(1);
  await page.getByRole('button', { name: '← Dozen' }).click();
  await expect(page.locator('.bar .here')).toHaveText('Start');
});

test('bulk import accepts =, |, tab, ; and comma, and skips other lines', async ({ page }) => {
  await openAdd(page, 'Eten');
  await page.fill('#f-bulk', [
    'bread = brood', 'cheese|kaas', 'milk\tmelk', 'egg ; ei', 'apple, appel',
    'no separator here', '', '   ', 'water = water = extra',
  ].join('\n'));
  await page.getByRole('button', { name: /Lijst toevoegen/ }).click();

  await expect(toast(page)).toHaveText('6 woorden toegevoegd');
  const added = (await saved(page)).cards.filter((c) => c.deckId === 2);
  expect(added.map((c) => `${c.native}=${c.dutch}`)).toEqual([
    'bread=brood', 'cheese=kaas', 'milk=melk', 'egg=ei', 'apple=appel', 'water=water',
  ]);
  expect(added.every((c) => c.box === 1)).toBe(true);
});

test('bulk import with no usable lines shows a toast and adds nothing', async ({ page }) => {
  await openAdd(page, 'Eten');
  await page.fill('#f-bulk', 'nothing to see\nhere either');
  await page.getByRole('button', { name: /Lijst toevoegen/ }).click();
  await expect(toast(page)).toHaveText('Geen regels herkend');
  expect((await saved(page)).cards).toHaveLength(1);
});
