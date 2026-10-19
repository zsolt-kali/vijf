// SPEC.md → Days in a row
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, menu } = require('./helpers');

/* Saturday 24 October 2026, noon: the week runs Monday 19 to Sunday 25. */
const SAT = new Date('2026-10-24T12:00:00');
const at = async (page) => page.clock.install({ time: SAT });
const streak = (page) => page.locator('.streak');
const withDays = (d, days) => Object.assign(d, { doneDays: days });

test('the deck list starts a streak when there are cards, and shows none without', async ({ page }) => {
  await at(page);
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a', 1)]));
  await expect(streak(page).locator('.days')).toHaveText('0 days in a row');
  await expect(streak(page).locator('.sub')).toHaveText('Finish today to start a streak');
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], []));
  await expect(streak(page)).toHaveCount(0);
});

test('days in a row count back from today; today not done yet doesn\'t break it', async ({ page }) => {
  await at(page);
  await open(page, withDays(data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a', 1)]),
    ['2026-10-22', '2026-10-23']));
  await expect(streak(page).locator('.days')).toHaveText('2 days in a row');
  await expect(streak(page).locator('.sub')).toHaveText('Finish today to make it 3');
  // this week: Thu and Fri done, Sat is today, Sun still to come
  await expect(streak(page).locator('.week i')).toHaveClass(['', '', '', 'done', 'done', 'today', '']);
});

test('one missed day a week is let off; a second one ends the streak', async ({ page }) => {
  await at(page);
  // Wed 21 missed: let off
  await open(page, withDays(data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a', 1)]),
    ['2026-10-19', '2026-10-20', '2026-10-22', '2026-10-23']));
  await expect(streak(page).locator('.days')).toHaveText('4 days in a row');
  // Tue 20 and Wed 21 missed: the second ends it
  await open(page, withDays(data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a', 1)]),
    ['2026-10-19', '2026-10-22', '2026-10-23']));
  await expect(streak(page).locator('.days')).toHaveText('2 days in a row');
});

test('a day with nothing due counts as done', async ({ page }) => {
  await at(page);
  const seen = Object.assign(card(1, 1, 'a', 'a', 2), { seenAt: SAT.getTime() - 3600e3, reviewedAt: SAT.getTime() - 3600e3 });
  await open(page, data([deck(1, 'Start'), deck(2, 'Eten')], [seen]));
  await expect(streak(page).locator('.days')).toHaveText('1 day in a row');
  expect((await saved(page)).doneDays).toEqual(['2026-10-24']);
});

test('finishing the last card of the day shows Done for today', async ({ page }) => {
  await at(page);
  await open(page, withDays(data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1), card(2, 1, 'house', 'huis', 1)]),
    ['2026-10-23']));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /I know it/ }).click();
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: 'Go again' }).click();
  await page.getByRole('button', { name: /I know it/ }).click();

  await expect(page.getByRole('heading', { name: 'Done for today.' })).toBeVisible();
  await expect(page.locator('.done-count')).toHaveText(/2\s+days in a row/);
  await expect(page.locator('.done-rows div').nth(0)).toHaveText(/Today\s*2 cards · 2 moved up/);
  await expect(page.locator('.done-rows div').nth(1)).toHaveText(/Tomorrow\s*0 cards/);
  expect((await saved(page)).doneDays).toEqual(['2026-10-23', '2026-10-24']);

  await page.getByRole('button', { name: 'Back to decks' }).click();
  await expect(page.locator('.wordmark')).toBeVisible();
});

test('after today is done, the deck list says so and when the next cards come', async ({ page }) => {
  await at(page);
  // a box 1 card known yesterday is due today... answered today in box 2, so due Monday
  const done = Object.assign(card(1, 1, 'a', 'a', 1), { seenAt: SAT.getTime() - 3600e3, reviewedAt: null });
  await open(page, withDays(data([deck(1, 'Start'), deck(2, 'Eten')], [done]), ['2026-10-23']));
  await expect(streak(page).locator('.days b')).toHaveClass('on');
  await expect(streak(page).locator('.days')).toHaveText('2 days in a row');
  await expect(streak(page).locator('.sub')).toHaveText('Done for today · Tomorrow 1 card');
});

test('the summary still shows when other cards are due today', async ({ page }) => {
  await at(page);
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 3)]));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(page.getByRole('heading', { name: 'Round complete.' })).toBeVisible();
});

test('the Days in a row switch hides the streak, but done days are still recorded', async ({ page }) => {
  await at(page);
  await open(page, withDays(data([deck(1, 'Start'), deck(2, 'Eten')], [card(1, 1, 'a', 'a', 1)]), ['2026-10-23']));
  await menu(page, 'Settings');
  await page.getByRole('switch', { name: 'Days in a row' }).click();
  await page.getByRole('button', { name: '← Decks' }).click();
  await expect(streak(page)).toHaveCount(0);

  await page.locator('.slot--deck', { hasText: 'Start' }).click();
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(page.getByRole('heading', { name: 'Done for today.' })).toBeVisible();
  await expect(page.locator('.done-card')).toHaveCount(0);
  await expect(page.locator('.done-rows div')).toHaveCount(2);
  expect((await saved(page)).doneDays).toEqual(['2026-10-23', '2026-10-24']);
});

