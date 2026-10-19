// SPEC.md → Leitner rules
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, toast, menu } = require('./helpers');

const remaining = (page) => page.locator('.bar > span').last();
/* A due card in a box the test doesn't touch, so finishing the test's box doesn't finish the
   day (which would show Done for today instead of the summary; see streak.spec.js). */
const later = (box) => card(99, 1, 'later', 'later', box);

test('I know it moves a card up one box and records the review', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'the house', 'het huis', 2), later(4)]));
  await page.click('[data-go=box2]');
  await page.getByRole('button', { name: /I know it/ }).click();

  const s = await saved(page);
  expect(s.cards[0].box).toBe(3);
  expect(s.cards[0].reviewedAt).toEqual(expect.any(Number));
  await expect(page.getByRole('heading', { name: 'Round complete.' })).toBeVisible();
});

test('Not yet keeps the card in its box and brings it back later in the session', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1), later(4)]));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: 'Go again' }).click();

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
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'tomorrow', 'morgen', 5), card(2, 1, 'busy', 'druk', 5), later(3)]));
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
  const missed = s.cards.find((c) => c.native === first), kept = s.cards.find((c) => c.native !== first && c.id !== 99);
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

test('a box 1 round with Not yet cards ends on a screen to go again or stop', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1), card(3, 1, 'c', 'c', 1)]));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /I know it/ }).click();
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: /Not yet/ }).click();

  await expect(page.getByRole('heading', { name: 'Round 1 done.' })).toBeVisible();
  await expect(page.getByText('2 not yet.')).toBeVisible();
  await page.getByRole('button', { name: 'Go again' }).click();
  await expect(remaining(page)).toHaveText('1 / 2');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(page.getByRole('heading', { name: 'Round 2 done.' })).toBeVisible();
  await expect(page.getByText('1 not yet.')).toBeVisible();

  // Stop for today: back to the boxes, and the missed card waits until tomorrow
  await page.getByRole('button', { name: 'Stop for today' }).click();
  await expect(box(page, 1).locator('.sub')).toHaveText('Next tomorrow');
  expect((await saved(page)).cards.filter((c) => c.box === 1)).toHaveLength(1);
});

test('a box 1 round with every card known goes straight to the summary', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), later(4)]));
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(page.getByRole('heading', { name: 'Round complete.' })).toBeVisible();
});

test('no answer ever changes the total: Not yet cards come back as the next round', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1), card(3, 1, 'c', 'c', 1), later(4)]));
  await page.click('[data-go=box1]');
  const know = () => page.getByRole('button', { name: /I know it/ }).click();
  const notYet = () => page.getByRole('button', { name: /Not yet/ }).click();
  const again = () => page.getByRole('button', { name: 'Go again' }).click();

  await expect(remaining(page)).toHaveText('1 / 3');
  await know();
  await expect(remaining(page)).toHaveText('2 / 3');
  await notYet();
  await expect(remaining(page)).toHaveText('3 / 3');
  await notYet();
  // round 2: the two Not yet cards
  await again();
  await expect(remaining(page)).toHaveText('1 / 2');
  await know();
  await expect(remaining(page)).toHaveText('2 / 2');
  await notYet();
  // round 3: the one card still not known
  await again();
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
  await page.getByRole('button', { name: 'Go again' }).click();
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
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1), card(2, 1, 'house', 'huis', 2), later(5)]));
  await expect(box(page, 1).locator('.sub')).toHaveCount(0);
  await page.click('[data-go=box1]');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: 'Go again' }).click();
  await page.getByRole('button', { name: /Not yet/ }).click();   // the next round, still in the session
  await page.getByRole('button', { name: 'Go again' }).click();
  await page.getByRole('button', { name: /I know it/ }).click();
  await page.getByRole('button', { name: 'Back to boxes' }).click();

  // the card moved up to box 2 is not due there today either
  await expect(box(page, 1)).toHaveAttribute('data-empty', '1');
  await expect(box(page, 2).locator('.sub')).toHaveText('1 left today');
  await expect(box(page, 2).locator('.cnt')).toHaveText('2');
  await page.click('[data-go=box2]');
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
    later(2),
  ]));
  await expect(box(page, 4).locator('.sub')).toHaveText('1 left today');
  await page.click('[data-go=box4]');
  await page.getByRole('button', { name: /I know it/ }).click();
  await page.getByRole('button', { name: 'Back to boxes' }).click();
  await expect(box(page, 4).locator('.sub')).toHaveText('Next tomorrow');
  await expect(box(page, 5).locator('.sub')).toHaveText('Next in 16 days');
});

test('in boxes 2–5, Not yet moves a card down one box and out of the session', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 3), card(2, 1, 'b', 'b', 3), later(5)]));
  await page.click('[data-go=box3]');
  await expect(page.getByRole('button', { name: /Not yet/ })).toContainText('back to box 2');
  const first = await page.locator('.face:not(.face--back) .word').textContent();
  await page.getByRole('button', { name: /Not yet/ }).click();
  await expect(remaining(page)).toHaveText('2 / 2');
  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(page.getByText('Moved up to box 4: 1. Back to box 2: 1.')).toBeVisible();

  const missed = (await saved(page)).cards.find((c) => c.native === first);
  expect(missed.box).toBe(2);
  await page.getByRole('button', { name: 'Back to boxes' }).click();
  await expect(box(page, 2).locator('.sub')).toHaveText('Next tomorrow');
});

test('a card moved up by an older version (reviewedAt a moment before seenAt) still waits its gap', async ({ page }) => {
  const at = daysAgo(1);
  await open(page, data([deck(1, 'Start')], [Object.assign(card(1, 1, 'a', 'a', 3), { reviewedAt: at, seenAt: at + 1 })]));
  await expect(box(page, 3).locator('.sub')).toHaveText('Next in 3 days');
});

/* The "Not yet" setting: one box down (default) or back to box 1 (classic Leitner). */
test('with Classic Leitner on, Not yet sends a card from any box to box 1', async ({ page }) => {
  await open(page, data([], []));
  await menu(page, 'Settings');
  const sw = page.getByRole('switch', { name: 'Classic Leitner' });
  await expect(sw).toHaveAttribute('aria-checked', 'false');
  await expect(page.locator('.setting .sub').first()).toHaveText('Missed cards go down one box');
  await sw.click();
  await expect(sw).toHaveAttribute('aria-checked', 'true');
  await expect(page.locator('.setting .sub').first()).toHaveText('Missed cards go back to box 1');

  await page.evaluate(() => {
    localStorage.setItem('leitner-dutch-v1', JSON.stringify({ cards: [
      { id: 1, deckId: 1, native: 'a', dutch: 'a', box: 4, createdAt: 1, reviewedAt: null, seenAt: null },
      { id: 2, deckId: 1, native: 'b', dutch: 'b', box: 4, createdAt: 2, reviewedAt: null, seenAt: null },
      { id: 3, deckId: 1, native: 'later', dutch: 'later', box: 2, createdAt: 3, reviewedAt: null, seenAt: null },
    ], nextId: 4, decks: [{ id: 1, name: 'Start', createdAt: 1 }], nextDeckId: 2 }));
  });
  await page.reload();
  await page.click('[data-go=box4]');
  await expect(page.getByRole('button', { name: /Not yet/ })).toContainText('back to box 1');
  await page.getByRole('button', { name: /Not yet/ }).click();
  await page.getByRole('button', { name: /I know it/ }).click();
  await expect(page.getByText('Moved up to box 5: 1. Back to box 1: 1.')).toBeVisible();
  expect((await saved(page)).cards.filter((c) => c.id !== 3).map((c) => c.box).sort()).toEqual([1, 5]);
});

test('the setting is kept in this browser only, apart from the cards', async ({ page }) => {
  await open(page, data([], []));
  await menu(page, 'Settings');
  await page.getByRole('switch', { name: 'Classic Leitner' }).click();
  await page.reload();
  await menu(page, 'Settings');
  await expect(page.getByRole('switch', { name: 'Classic Leitner' })).toHaveAttribute('aria-checked', 'true');
  expect(await page.evaluate(() => localStorage.getItem('vijf-miss'))).toBe('box1');
  expect(await page.evaluate(() => localStorage.getItem('leitner-dutch-v1') || '')).not.toContain('box1');
});

test('Settings holds three switches, and cards have no speaker', async ({ page }) => {
  await open(page, data([], []));
  await menu(page, 'Settings');
  await expect(page.getByRole('switch')).toHaveCount(3);
  for (const [name, on] of [['Classic Leitner', 'false'], ['Search', 'true'], ['Days in a row', 'true']]) {
    await expect(page.getByRole('switch', { name })).toHaveAttribute('aria-checked', on);
  }
  await expect(page.locator('[data-act=speed], [data-act=voice]')).toHaveCount(0);
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'busy', 'druk', 1)]));
  await page.click('[data-go=box1]');
  await expect(page.locator('.speak')).toHaveCount(0);
  await expect(page.locator('.face--back .cog')).toHaveCount(1);
});

