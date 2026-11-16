// SPEC.md → Example sentences
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved } = require('./helpers');

const withEx = (c, n, d) => Object.assign(c, n ? { nativeExample: n } : {}, d ? { dutchExample: d } : {});
const one = (c) => data([deck(1, 'Start')], [c]);
const front = (page) => page.locator('.face:not(.face--back)');
const back = (page) => page.locator('.face--back');

const settings = async (page) => {
  await page.click('[data-act=menu]');
  await page.getByRole('menuitem', { name: 'Settings' }).click();
};

test('sentences show under the word on both sides, with no bubble or other button', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'the house', 'het huis', 1), 'The house is big.', 'Het huis is groot.')));
  await page.click('[data-go=box1]');
  await expect(front(page).locator('.example')).toHaveText('The house is big.');
  await expect(front(page).locator('.example u')).toHaveText('The house');
  await expect(page.locator('.bubble, [data-act=example]')).toHaveCount(0);
  await page.click('#flip');
  await expect(back(page).locator('.example')).toBeVisible();
  await expect(back(page).locator('.example u')).toHaveText('Het huis');
});

test('a side without a sentence shows only its word', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'the bread', 'het brood', 1), null, 'Het brood is vers.')));
  await page.click('[data-go=box1]');
  await expect(front(page).locator('.example')).toHaveCount(0);
  await expect(back(page).locator('.example')).toHaveCount(1);
});

test('Settings → Example sentences is on by default; off hides them everywhere, and it is kept', async ({ page }) => {
  await open(page, data([deck(1, 'Start'), deck(2, 'Werk')],
    [withEx(card(1, 1, 'the house', 'het huis', 1), 'The house is big.', null)]));
  await settings(page);
  const sw = page.getByRole('switch', { name: 'Example sentences' });
  await expect(sw).toHaveAttribute('aria-checked', 'true');
  await expect(page.locator('.setting', { hasText: 'Example sentences' })).toContainText('Shown on the cards');
  await sw.click();
  await expect(sw).toHaveAttribute('aria-checked', 'false');
  await expect(page.locator('.setting', { hasText: 'Example sentences' })).toContainText('Hidden');
  await page.reload();
  await page.locator('.slot--deck', { hasText: 'Start' }).click();
  await page.click('[data-go=box1]');
  await expect(page.locator('.example')).toHaveCount(0);
  await page.goto('/');
  await settings(page);
  await page.getByRole('switch', { name: 'Example sentences' }).click();
  await page.reload();
  await page.locator('.slot--deck', { hasText: 'Start' }).click();
  await page.getByRole('button', { name: 'Browse cards' }).click();
  await expect(front(page).locator('.example')).toHaveText('The house is big.');
});

test('an older saved "on" still reads as on', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'the house', 'het huis', 1), 'The house is big.', null)));
  await page.evaluate(() => localStorage.setItem('vijf-examples', '1'));
  await page.reload();
  await page.click('[data-go=box1]');
  await expect(front(page).locator('.example')).toBeVisible();
});

test('the word is underlined ignoring case and accents, and not when it does not appear', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [
    withEx(card(1, 1, 'to work', 'werken', 1), 'I like to work here.', 'Ik werk hier graag.'),
  ]));
  await page.click('[data-go=box1]');
  await expect(front(page).locator('.example u')).toHaveText('to work');
  await expect(back(page).locator('.example u')).toHaveCount(0);
});

test('sentences are escaped, never markup', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'a', 'b', 1), '<b>hi</b> a', null)));
  await page.click('[data-go=box1]');
  await expect(front(page).locator('.example')).toHaveText('<b>hi</b> a');
});

test('editing a card changes, adds or removes its sentences and keeps its box', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'the house', 'het huis', 3), 'The house is big.', null)));
  await page.click('[data-go=box3]');
  await front(page).locator('.cog').click();
  await expect(page.locator('#f-edit-native-ex')).toHaveValue('The house is big.');
  await page.fill('#f-edit-native-ex', '');
  await page.fill('#f-edit-dutch-ex', '  Het huis is groot.  ');
  await page.getByRole('button', { name: 'Save' }).click();
  const c = (await saved(page)).cards[0];
  expect(c.nativeExample).toBeUndefined();
  expect(c.dutchExample).toBe('Het huis is groot.');
  expect(c.box).toBe(3);
});

test('the starter words come with sentences', async ({ page }) => {
  await open(page, data([], []));
  await page.getByRole('button', { name: /starter words/ }).click();
  const cards = (await saved(page)).cards;
  expect(cards).toHaveLength(12);
  expect(cards.every((c) => c.nativeExample && c.dutchExample)).toBe(true);
});
