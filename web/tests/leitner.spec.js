// SPEC.md → Leitner rules
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, toast } = require('./helpers');

const remaining = (page) => page.locator('.bar > span').last();

test('I know it moves a card up one box and records the review', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'the house', 'het huis', 2)]));
  await page.click('[data-go=box2]');
  await page.getByRole('button', { name: /I know it/ }).click();

  const s = await saved(page);
  expect(s.cards[0].box).toBe(3);
  expect(s.cards[0].reviewedAt).toEqual(expect.any(Number));
  await expect(page.getByRole('heading', { name: 'Round complete.' })).toBeVisible();
});

test('Not yet keeps the card in its box and brings it back later in the session', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1)]));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /Not yet/ }).click();

  await expect(remaining(page)).toHaveText('1 / 1');
  await expect(page.locator('.face:not(.face--back) .word')).toHaveText('busy');
  expect((await saved(page)).cards[0].box).toBe(1);

  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(page.getByText('Moved up to box 2: 1. Not yet: 1.')).toBeVisible();
});

test('tapping the card flips it to show the Dutch word', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1)]));
  await page.click('[data-go=box1]');
  await expect(page.locator('#flip')).not.toHaveClass(/turned/);
  await page.click('#flip');
  await expect(page.locator('#flip')).toHaveClass(/turned/);
  await expect(page.locator('.face--back .word')).toHaveText('druk');
});

test('box 5 is review only: Next, no rating, cards stay in box 5', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'tomorrow', 'morgen', 5)]));
  await page.click('[data-go=box5]');

  await expect(page.getByRole('button', { name: /I know it/ })).toHaveCount(0);
  await expect(page.getByRole('button', { name: /Not yet/ })).toHaveCount(0);
  await page.getByRole('button', { name: /Next/ }).click();

  await expect(page.getByRole('heading', { name: 'Round complete.' })).toBeVisible();
  expect((await saved(page)).cards[0].box).toBe(5);
});

test('tapping an empty box shows a toast and stays on the boxes', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1)]));
  await page.click('[data-go=box3]');
  await expect(toast(page)).toHaveText('Box 3 is empty');
  await expect(page.locator('[data-go=box1]')).toBeVisible();
});

test('a study session only includes cards from the open deck', async ({ page }) => {
  await open(page, data(
    [deck(1, 'Start'), deck(2, 'Eten')],
    [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1), card(3, 2, 'c', 'c', 1)],
  ));
  await page.locator('[data-deck="1"]').click();
  await page.click('[data-go=box1]');
  await expect(remaining(page)).toHaveText('1 / 2');
});

test('no answer ever changes the total: Not yet cards come back as the next round', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1), card(3, 1, 'c', 'c', 1)]));
  await page.click('[data-go=box1]');
  const know = () => page.getByRole('button', { name: /I know it/ }).click();
  const notYet = () => page.getByRole('button', { name: /Not yet/ }).click();

  await expect(remaining(page)).toHaveText('1 / 3');
  await know();
  await expect(remaining(page)).toHaveText('2 / 3');
  await notYet();
  await expect(remaining(page)).toHaveText('3 / 3');
  await notYet();
  // round 2: the two Not yet cards
  await expect(remaining(page)).toHaveText('1 / 2');
  await know();
  await expect(remaining(page)).toHaveText('2 / 2');
  await notYet();
  // round 3: the one card still not known
  await expect(remaining(page)).toHaveText('1 / 1');
  await know();
  await expect(page.getByText('Moved up to box 2: 3. Not yet: 3.')).toBeVisible();
});

test('Not yet cards come back in the order they were answered', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1), card(3, 1, 'c', 'c', 1)]));
  await page.click('[data-go=box1]');
  const word = page.locator('.face:not(.face--back) .word');
  const firstRound = [];
  for (let i = 0; i < 3; i++) {
    firstRound.push(await word.textContent());
    await page.getByRole('button', { name: /Not yet/ }).click();
  }
  const secondRound = [];
  for (let i = 0; i < 3; i++) {
    await expect(remaining(page)).toHaveText(`${i + 1} / 3`);
    secondRound.push(await word.textContent());
    await page.getByRole('button', { name: /I know it/ }).click();
  }
  expect(secondRound).toEqual(firstRound);
});
