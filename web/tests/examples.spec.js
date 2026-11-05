// SPEC.md → Example sentences
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved } = require('./helpers');

const withEx = (c, n, d) => Object.assign(c, n ? { nativeExample: n } : {}, d ? { dutchExample: d } : {});
const one = (c) => data([deck(1, 'Start')], [c]);
const front = (page) => page.locator('.face:not(.face--back)');
const back = (page) => page.locator('.face--back');

test('a card with a sentence shows the bubble; tapping it shows the sentence without flipping', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'the house', 'het huis', 1), 'The house is big.', 'Het huis is groot.')));
  await page.click('[data-go=box1]');
  const bubble = front(page).locator('.bubble');
  await expect(bubble).toHaveAttribute('aria-label', 'Show the example sentence');
  await expect(front(page).locator('.example')).toBeHidden();
  await bubble.click();
  await expect(front(page).locator('.example')).toHaveText('The house is big.');
  await expect(front(page).locator('.example u')).toHaveText('The house');
  await expect(bubble).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('#flip')).not.toHaveClass(/turned/);
});

test('the sentence stays open when the card flips, and the next card starts hidden', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [
    withEx(card(1, 1, 'the house', 'het huis', 1), 'The house is big.', 'Het huis is groot.'),
    withEx(card(2, 1, 'the bread', 'het brood', 1), 'The bread is fresh.', 'Het brood is vers.'),
  ]));
  await page.click('[data-go=box1]');
  await front(page).locator('.bubble').click();
  await page.click('#flip');
  await expect(back(page).locator('.example')).toBeVisible();
  await expect(back(page).locator('.example u')).toHaveText(/Het (huis|brood)/);
  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(front(page).locator('.example')).toBeHidden();
  await page.click('#flip');
  await back(page).locator('.bubble').click();   // the back's bubble works the same way
  await expect(back(page).locator('.example')).toBeVisible();
  await back(page).locator('.bubble').click();
  await expect(back(page).locator('.example')).toBeHidden();
});

test('only a side with a sentence has the bubble; a card without any looks as before', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [
    withEx(card(1, 1, 'the bread', 'het brood', 1), null, 'Het brood is vers.'),
  ]));
  await page.click('[data-go=box1]');
  await expect(front(page).locator('.bubble')).toHaveCount(0);
  await expect(back(page).locator('.bubble')).toHaveCount(1);
  await open(page, one(card(1, 1, 'the cheese', 'de kaas', 1)));
  await page.click('[data-go=box1]');
  await expect(page.locator('.bubble')).toHaveCount(0);
});

test('the word is underlined ignoring case and accents, and not when it does not appear', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [
    withEx(card(1, 1, 'to work', 'werken', 1), 'I like to work here.', 'Ik werk hier graag.'),
  ]));
  await page.click('[data-go=box1]');
  await front(page).locator('.bubble').click();
  await expect(front(page).locator('.example u')).toHaveText('to work');
  await expect(back(page).locator('.example u')).toHaveCount(0);
});

test('sentences are escaped, never markup', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'a', 'b', 1), '<b>hi</b> a', null)));
  await page.click('[data-go=box1]');
  await front(page).locator('.bubble').click();
  await expect(front(page).locator('.example')).toHaveText('<b>hi</b> a');
});

test('Browse cards shows the bubble too', async ({ page }) => {
  await open(page, one(withEx(card(1, 1, 'the house', 'het huis', 1), 'The house is big.', 'Het huis is groot.')));
  await page.getByRole('button', { name: 'Browse cards' }).click();
  await front(page).locator('.bubble').click();
  await expect(front(page).locator('.example')).toHaveText('The house is big.');
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
