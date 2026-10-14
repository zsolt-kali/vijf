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

test('in box 5, I know it keeps the card there and Not yet moves it back to box 4', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'tomorrow', 'morgen', 5), card(2, 1, 'busy', 'druk', 5)]));
  await page.click('[data-go=box5]');
  await expect(page.getByRole('button', { name: /Not yet/ })).toContainText('back to box 4');
  await expect(page.getByRole('button', { name: /I know it/ })).toContainText('stays in box 5');

  const first = await page.locator('.face:not(.face--back) .word').textContent();
  await page.getByRole('button', { name: /Not yet/ }).click();
  await expect(remaining(page)).toHaveText('2 / 2');
  await page.getByRole('button', { name: /I know it/ }).click();

  // the missed card doesn't come round again in this session
  await expect(page.getByText('Stayed in box 5: 1. Back to box 4: 1.')).toBeVisible();
  const s = await saved(page);
  const missed = s.cards.find((c) => c.native === first), kept = s.cards.find((c) => c.native !== first);
  expect(missed.box).toBe(4);
  expect(missed.reviewedAt).toBeNull();
  expect(kept.box).toBe(5);
  expect(kept.reviewedAt).toBe(kept.seenAt);
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

/* Spaced repetition: box n comes up every 1, 2, 4, 8 or 16 days; "Not yet" brings a card back tomorrow. */
const box = (page, n) => page.locator(`[data-go=box${n}]`);
/* Noon, `n` days ago. */
const daysAgo = (n) => { const d = new Date(); d.setHours(12, 0, 0, 0); d.setDate(d.getDate() - n); return d.getTime(); };
const knownAt = (c, at) => Object.assign(c, { seenAt: at, reviewedAt: at });
const missedAt = (c, at) => Object.assign(c, { seenAt: at, reviewedAt: null });

test('both answers record when the card was seen', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1)]));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: /I know it/ }).click();
  const s = await saved(page);
  expect(s.cards[0].seenAt).toEqual(expect.any(Number));
  expect(s.cards[1].seenAt).toEqual(expect.any(Number));
});

test('a card answered today is not shown again until tomorrow', async ({ page }) => {
  const today = new Date(); today.setHours(0, 0, 0, 0);
  const seen = (c, at) => Object.assign(c, { seenAt: at });
  await open(page, data([deck(1, 'Start')], [
    seen(card(1, 1, 'today', 'vandaag', 1), today.getTime() + 1000),
    seen(card(2, 1, 'yesterday', 'gisteren', 1), today.getTime() - 1000),
    card(3, 1, 'never', 'nooit', 1),
  ]));
  await expect(box(page, 1).locator('.sub')).toHaveText('2 left today');
  await expect(box(page, 1).locator('.cnt')).toHaveText('3');
  await page.click('[data-go=box1]');
  await expect(remaining(page)).toHaveText('1 / 2');
  await expect(page.locator('.face:not(.face--back) .word')).not.toHaveText('today');
});

test('a box studied through is done for today and cannot be opened', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1), card(2, 1, 'house', 'huis', 2)]));
  await expect(box(page, 1).locator('.sub')).toHaveCount(0);
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: /Not yet/ }).click();   // the next round, still in the session
  await page.getByRole('button', { name: /I know it/ }).click();
  await page.getByRole('button', { name: 'Back to boxes' }).click();

  // the card moved up to box 2 is not due there today either
  await expect(box(page, 1)).toHaveAttribute('data-empty', '1');
  await expect(box(page, 2).locator('.sub')).toHaveText('1 left today');
  await expect(box(page, 2).locator('.cnt')).toHaveText('2');
  await page.click('[data-go=box2]');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: /I know it/ }).click();
  await page.getByRole('button', { name: 'Back to boxes' }).click();

  // a box with nothing due says when its next card comes up
  await expect(box(page, 3).locator('.sub')).toHaveText('Next in 4 days');
  await expect(box(page, 3)).toHaveAttribute('data-empty', '1');
  await page.click('[data-go=box3]');
  await expect(toast(page)).toHaveText('Next in 4 days');
  await expect(box(page, 3)).toBeVisible();
});

test('each box comes up after its own gap: 1, 2, 4, 8 and 16 days', async ({ page }) => {
  const gaps = [1, 2, 4, 8, 16], cards = [];
  gaps.forEach((gap, i) => {
    cards.push(knownAt(card(2 * i + 1, 1, 'due' + i, 'due' + i, i + 1), daysAgo(gap)));
    cards.push(knownAt(card(2 * i + 2, 1, 'wait' + i, 'wait' + i, i + 1), daysAgo(gap - 1)));
  });
  await open(page, data([deck(1, 'Start')], cards));
  for (let n = 1; n <= 5; n++) await expect(box(page, n).locator('.sub')).toHaveText('1 left today');
  await page.click('[data-go=box4]');
  await expect(remaining(page)).toHaveText('1 / 1');
  await expect(page.locator('.face:not(.face--back) .word')).toHaveText('due3');
});

test('a card answered Not yet comes back the next day, whatever its box', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [
    missedAt(card(1, 1, 'yesterday', 'gisteren', 4), daysAgo(1)),
    missedAt(card(2, 1, 'today', 'vandaag', 4), daysAgo(0)),
  ]));
  await expect(box(page, 4).locator('.sub')).toHaveText('1 left today');
  await page.click('[data-go=box4]');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: /I know it/ }).click();   // the next round
  await page.getByRole('button', { name: 'Back to boxes' }).click();
  await expect(box(page, 4).locator('.sub')).toHaveText('Next tomorrow');
  await expect(box(page, 5).locator('.sub')).toHaveText('Next in 16 days');
});

test('a card moved up by an older version (reviewedAt a moment before seenAt) still waits its gap', async ({ page }) => {
  const at = daysAgo(1);
  await open(page, data([deck(1, 'Start')], [Object.assign(card(1, 1, 'a', 'a', 3), { reviewedAt: at, seenAt: at + 1 })]));
  await expect(box(page, 3).locator('.sub')).toHaveText('Next in 3 days');
});
