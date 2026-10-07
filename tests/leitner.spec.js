// SPEC.md → Leitner rules
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, toast } = require('./helpers');

const remaining = (page) => page.locator('.bar > span').last();

test('Ken ik moves a card up one box and records the review', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'the house', 'het huis', 2)]));
  await page.click('[data-go=box2]');
  await page.getByRole('button', { name: /Ken ik/ }).click();

  const s = await saved(page);
  expect(s.cards[0].box).toBe(3);
  expect(s.cards[0].reviewedAt).toEqual(expect.any(Number));
  await expect(page.getByRole('heading', { name: 'Ronde afgerond.' })).toBeVisible();
});

test('Nog niet keeps the card in its box and brings it back later in the session', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1)]));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /Nog niet/ }).click();

  await expect(remaining(page)).toHaveText('Doos 1 · 1 over');
  await expect(page.locator('.face:not(.face--back) .word')).toHaveText('busy');
  expect((await saved(page)).cards[0].box).toBe(1);

  await page.getByRole('button', { name: /Ken ik/ }).click();
  await expect(page.getByText('1 cards moved up to box 2. 1 stayed in box 1.')).toBeVisible();
});

test('tapping the card flips it to show the Dutch word', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1)]));
  await page.click('[data-go=box1]');
  await expect(page.locator('#flip')).not.toHaveClass(/turned/);
  await page.click('#flip');
  await expect(page.locator('#flip')).toHaveClass(/turned/);
  await expect(page.locator('.face--back .word')).toHaveText('druk');
});

test('box 5 is review only: Volgende, no rating, cards stay in box 5', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'tomorrow', 'morgen', 5)]));
  await page.click('[data-go=box5]');

  await expect(page.getByRole('button', { name: /Ken ik/ })).toHaveCount(0);
  await expect(page.getByRole('button', { name: /Nog niet/ })).toHaveCount(0);
  await page.getByRole('button', { name: /Volgende/ }).click();

  await expect(page.getByRole('heading', { name: 'Ronde afgerond.' })).toBeVisible();
  expect((await saved(page)).cards[0].box).toBe(5);
});

test('tapping an empty box shows a toast and stays on the boxes', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1)]));
  await page.click('[data-go=box3]');
  await expect(toast(page)).toHaveText('Doos 3 is leeg');
  await expect(page.locator('[data-go=box1]')).toBeVisible();
});

test('a study session only includes cards from the open deck', async ({ page }) => {
  await open(page, data(
    [deck(1, 'Start'), deck(2, 'Eten')],
    [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1), card(3, 2, 'c', 'c', 1)],
  ));
  await page.locator('[data-deck="1"]').click();
  await page.click('[data-go=box1]');
  await expect(remaining(page)).toHaveText('Doos 1 · 2 over');
});
