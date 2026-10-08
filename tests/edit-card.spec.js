// SPEC.md → Editing a card
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, saved, toast, study } = require('./helpers');

const oneCard = (box = 2) => data([deck(1, 'Start')], [card(1, 1, 'the hous', 'het huis', box)]);
const cog = (page) => page.locator('.face:not(.face--back) .cog');
const front = (page) => page.locator('.face:not(.face--back) .word');
const remaining = (page) => page.locator('.bar > span').last();

test('the cog sits inside the card, top-right, on both faces', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await expect(page.locator('.face .cog')).toHaveCount(2);
  await expect(page.locator('.rate .btn')).toHaveCount(2);

  const faceBox = await page.locator('.face:not(.face--back)').boundingBox();
  const cogBox = await cog(page).boundingBox();
  expect(faceBox.x + faceBox.width - (cogBox.x + cogBox.width)).toBeLessThan(12);
  expect(cogBox.y - faceBox.y).toBeLessThan(12);
  expect(cogBox.width).toBeGreaterThanOrEqual(44);
});

test('tapping the cog opens the editor without flipping the card first', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await cog(page).click();
  await expect(page.locator('#f-edit-native')).toBeVisible();

  await page.getByRole('button', { name: /Cancel/ }).click();
  await expect(page.locator('#flip')).not.toHaveClass(/turned/);
});

test('the cog on the back of the card opens the editor too', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await page.click('#flip');
  await page.locator('.face--back .cog').click();
  await expect(page.locator('#f-edit-dutch')).toHaveValue('het huis');
});

test('in box 5 the cog is inside the card and Next is alone below it', async ({ page }) => {
  await open(page, oneCard(5));
  await study(page, 'Start', 5);
  await expect(page.locator('.rate .btn')).toHaveCount(1);
  await expect(page.getByRole('button', { name: /Next/ })).toBeVisible();
  await expect(cog(page)).toBeVisible();
});

test('the cog opens a form with both meanings filled in', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await cog(page).click();

  await expect(page.locator('#f-edit-native')).toHaveValue('the hous');
  await expect(page.locator('#f-edit-dutch')).toHaveValue('het huis');
  await expect(page.getByRole('button', { name: /^Save$/ })).toBeVisible();
  await expect(page.getByRole('button', { name: /Cancel/ })).toBeVisible();
  await expect(page.getByRole('button', { name: /Delete card/ })).toHaveCSS('color', 'rgb(200, 16, 46)');
});

test('saving changes both meanings and keeps the box and review date', async ({ page }) => {
  const before = oneCard(3);
  before.cards[0].reviewedAt = 1234;
  await open(page, before);
  await study(page, 'Start', 3);
  await cog(page).click();
  await page.fill('#f-edit-native', 'the house');
  await page.fill('#f-edit-dutch', 'de woning');
  await page.getByRole('button', { name: /^Save$/ }).click();

  await expect(toast(page)).toHaveText('Saved');
  expect((await saved(page)).cards[0]).toMatchObject(
    { native: 'the house', dutch: 'de woning', box: 3, reviewedAt: 1234 });
  await expect(front(page)).toHaveText('the house');
  await expect(page.locator('.face--back .word')).toHaveText('de woning');
});

test('pressing Enter in a field saves', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await cog(page).click();
  await page.fill('#f-edit-native', 'the house');
  await page.press('#f-edit-native', 'Enter');
  expect((await saved(page)).cards[0].native).toBe('the house');
});

test('after saving, the same card is still current and the session continues', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1)]));
  await study(page, 'Start', 1);
  const word = await front(page).textContent();
  await cog(page).click();
  await page.fill('#f-edit-dutch', 'changed');
  await page.getByRole('button', { name: /^Save$/ }).click();

  await expect(front(page)).toHaveText(word);
  await expect(remaining(page)).toHaveText('1 / 2');
});

test('both fields are required', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await cog(page).click();
  await page.fill('#f-edit-dutch', '   ');
  await page.getByRole('button', { name: /^Save$/ }).click();

  await expect(toast(page)).toHaveText('Fill in both fields');
  expect((await saved(page)).cards[0].dutch).toBe('het huis');
  await expect(page.locator('#f-edit-dutch')).toBeVisible();
});

test('cancel returns to the card unchanged', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await cog(page).click();
  await page.fill('#f-edit-native', 'something else');
  await page.getByRole('button', { name: /Cancel/ }).click();

  await expect(front(page)).toHaveText('the hous');
  expect((await saved(page)).cards[0].native).toBe('the hous');
});

test('deleting a card removes it and moves on to the next card', async ({ page }) => {
  await open(page, data([deck(1, 'Start')], [card(1, 1, 'a', 'a', 1), card(2, 1, 'b', 'b', 1)]));
  await study(page, 'Start', 1);
  const word = await front(page).textContent();
  await cog(page).click();
  await page.getByRole('button', { name: /Delete card/ }).click();

  const left = (await saved(page)).cards.map((c) => c.native);
  expect(left).toEqual(['a', 'b'].filter((w) => w !== word));
  await expect(front(page)).toHaveText(left[0]);
  await expect(remaining(page)).toHaveText('1 / 1');
});

test('deleting the last card in the session shows the summary', async ({ page }) => {
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await cog(page).click();
  await page.getByRole('button', { name: /Delete card/ }).click();

  await expect(page.getByRole('heading', { name: 'Round complete.' })).toBeVisible();
  expect((await saved(page)).cards).toEqual([]);
});

test('undo brings the card back as the current card, in its box', async ({ page }) => {
  await open(page, oneCard(4));
  await study(page, 'Start', 4);
  await cog(page).click();
  await page.getByRole('button', { name: /Delete card/ }).click();
  await page.locator('.toast--undo').getByRole('button', { name: 'Undo' }).click();

  expect((await saved(page)).cards).toEqual(oneCard(4).cards);
  await expect(front(page)).toHaveText('the hous');
  await expect(remaining(page)).toHaveText('1 / 1');
});

test('undo after leaving the session restores the card without reopening it', async ({ page }) => {
  await open(page, oneCard(4));
  await study(page, 'Start', 4);
  await cog(page).click();
  await page.getByRole('button', { name: /Delete card/ }).click();
  await page.locator('.crumbs').getByRole('button', { name: 'Start' }).click();
  await page.locator('.toast--undo').getByRole('button', { name: 'Undo' }).click();

  await expect(page.locator('[data-go=box4] .cnt')).toHaveText('1');
  expect((await saved(page)).cards[0].box).toBe(4);
});

test('the card-delete undo disappears after 5 seconds and the delete stays', async ({ page }) => {
  await page.clock.install();
  await open(page, oneCard());
  await study(page, 'Start', 2);
  await cog(page).click();
  await page.getByRole('button', { name: /Delete card/ }).click();

  await page.clock.runFor(5500);
  await expect(page.locator('.toast--undo')).toHaveCount(0);
  expect((await saved(page)).cards).toEqual([]);
});
