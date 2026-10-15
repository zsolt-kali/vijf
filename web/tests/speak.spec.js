// SPEC.md → Hearing the Dutch word
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, study, menu } = require('./helpers');

const sample = () => data(
  [deck(1, 'Start'), deck(2, 'Eten')],
  [card(1, 1, 'the house', 'het huis', 2), card(2, 1, 'the bread', 'het brood', 5)],
);

/* Replaces the browser's speech engine with a recorder, so tests can see what was said. */
async function fakeSpeech(page, voices = [{ lang: 'en-US', name: 'English' }, { lang: 'nl-NL', name: 'Xander' }]) {
  voices = voices.map((v) => Object.assign({ voiceURI: v.name }, v));
  await page.addInitScript((list) => {
    window.__said = [];
    window.__cancels = 0;
    window.SpeechSynthesisUtterance = function (text) { this.text = text; };
    Object.defineProperty(window, 'speechSynthesis', {
      value: {
        getVoices: () => list,
        speak: (u) => window.__said.push({ text: u.text, lang: u.lang, voice: u.voice && u.voice.name, rate: u.rate }),
        cancel: () => { window.__cancels++; },
      },
    });
  }, voices);
}
const said = (page) => page.evaluate(() => window.__said);
const speaker = (page) => page.locator('.face--back .speak');

test('the back of the card has a speaker button; the front does not', async ({ page }) => {
  await fakeSpeech(page);
  await open(page, sample());
  await study(page, 'Start', 2);
  await expect(page.locator('.face:not(.face--back) .speak')).toHaveCount(0);
  await expect(speaker(page)).toHaveCount(1);
  await expect(speaker(page)).toHaveAttribute('aria-label', 'Say the Dutch word');
  expect((await speaker(page).boundingBox()).width).toBeGreaterThanOrEqual(44);
});

test('tapping the speaker says the Dutch word in a Dutch voice without flipping back', async ({ page }) => {
  await fakeSpeech(page);
  await open(page, sample());
  await study(page, 'Start', 2);
  await page.click('#flip');
  await speaker(page).click();

  expect(await said(page)).toEqual([{ text: 'het huis', lang: 'nl-NL', voice: 'Xander', rate: 1 }]);
  await expect(page.locator('#flip')).toHaveClass(/turned/);
});

test('without a Dutch voice it still asks for Dutch', async ({ page }) => {
  await fakeSpeech(page, [{ lang: 'en-US', name: 'English' }]);
  await open(page, sample());
  await study(page, 'Start', 2);
  await page.click('#flip');
  await speaker(page).click();
  expect(await said(page)).toEqual([{ text: 'het huis', lang: 'nl-NL', rate: 1 }]);
});

test('it works in box 5 too', async ({ page }) => {
  await fakeSpeech(page);
  await open(page, sample());
  await study(page, 'Start', 5);
  await page.click('#flip');
  await speaker(page).click();
  expect((await said(page)).map((s) => s.text)).toEqual(['het brood']);
});

test('moving on to the next card stops the speech', async ({ page }) => {
  await fakeSpeech(page);
  await open(page, sample());
  await study(page, 'Start', 2);
  await page.click('#flip');
  await speaker(page).click();
  const before = await page.evaluate(() => window.__cancels);
  await page.getByRole('button', { name: /I know it/ }).click();
  expect(await page.evaluate(() => window.__cancels)).toBeGreaterThan(before);
});

test('with no speech support there is no speaker button', async ({ page }) => {
  await page.addInitScript(() => { delete window.speechSynthesis; delete window.SpeechSynthesisUtterance; });
  await open(page, sample());
  await study(page, 'Start', 2);
  await expect(page.locator('.speak')).toHaveCount(0);
  await expect(page.locator('.face--back .cog')).toHaveCount(1);
});

/* The Voice screen */
const voices = [
  { lang: 'en-US', name: 'Samantha' }, { lang: 'nl-NL', name: 'Xander' },
  { lang: 'nl-BE', name: 'Ellen' }, { lang: 'nl-NL', name: 'Claire (Premium)' },
];
const sayOnCard = async (page) => {
  await study(page, 'Start', 2);
  await page.click('#flip');
  await speaker(page).click();
  return (await said(page)).at(-1);
};

test('the Voice screen lists the Dutch voices and marks the one in use', async ({ page }) => {
  await fakeSpeech(page, voices);
  await open(page, data([], []));
  await menu(page, 'Voice');
  const rows = page.locator('.slot--voice');
  await expect(rows.locator('.lbl')).toHaveText(['Xander', 'Ellen', 'Claire (Premium)']);
  await expect(rows.locator('.sub')).toHaveText(['Netherlands', 'Belgium', 'Netherlands']);
  await expect(rows.nth(0)).toHaveAttribute('aria-pressed', 'true');
  await expect(rows.nth(0).locator('.in-use')).toHaveText('In use');
  await expect(page.getByRole('button', { name: 'Normal' })).toHaveAttribute('aria-pressed', 'true');
});

test('choosing a voice and a speed reads a sample, and the card uses them after a reload', async ({ page }) => {
  await fakeSpeech(page, voices);
  await open(page, sample());
  await menu(page, 'Voice');
  await page.locator('.slot--voice', { hasText: 'Claire' }).click();
  expect((await said(page)).at(-1)).toEqual({ text: 'Goedemorgen', lang: 'nl-NL', voice: 'Claire (Premium)', rate: 1 });
  await page.getByRole('button', { name: 'Slow' }).click();
  expect((await said(page)).at(-1)).toMatchObject({ voice: 'Claire (Premium)', rate: 0.7 });
  await expect(page.locator('.slot--voice', { hasText: 'Claire' })).toHaveAttribute('aria-pressed', 'true');

  await page.reload();
  expect(await sayOnCard(page)).toEqual({ text: 'het huis', lang: 'nl-NL', voice: 'Claire (Premium)', rate: 0.7 });
});

test('the choice is kept apart from the cards, so backups do not carry it', async ({ page }) => {
  await fakeSpeech(page, voices);
  await open(page, data([], []));
  await menu(page, 'Voice');
  await page.getByRole('button', { name: 'Fast' }).click();
  const stored = await page.evaluate(() => ({ pick: localStorage.getItem('vijf-voice'), cards: localStorage.getItem('leitner-dutch-v1') }));
  expect(JSON.parse(stored.pick)).toEqual({ voice: '', speed: 'fast' });
  expect(stored.cards).not.toContain('fast');
});

test('without a choice a voice from the Netherlands is used, even if a Belgian one is listed first', async ({ page }) => {
  await fakeSpeech(page, [{ lang: 'nl-BE', name: 'Ellen' }, { lang: 'nl-NL', name: 'Xander' }]);
  await open(page, sample());
  expect(await sayOnCard(page)).toMatchObject({ voice: 'Xander', rate: 1 });
});

test('a chosen voice that is gone falls back to the first Dutch voice', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('vijf-voice', JSON.stringify({ voice: 'Gone', speed: 'fast' })));
  await fakeSpeech(page, voices);
  await open(page, sample());
  expect(await sayOnCard(page)).toMatchObject({ voice: 'Xander', rate: 1.25 });
});

test('with no Dutch voice the Voice screen says how to add one', async ({ page }) => {
  await fakeSpeech(page, [{ lang: 'en-US', name: 'Samantha' }]);
  await open(page, data([], []));
  await menu(page, 'Voice');
  await expect(page.getByText('No Dutch voice on this device yet.')).toBeVisible();
  await expect(page.getByText(/Manage Voices → Dutch/)).toBeVisible();
});

test('with no speech support there is no Voice in the menu', async ({ page }) => {
  await page.addInitScript(() => { delete window.speechSynthesis; delete window.SpeechSynthesisUtterance; });
  await open(page, data([], []));
  await page.getByRole('button', { name: 'More' }).click();
  await expect(page.getByRole('menuitem', { name: 'Voice' })).toHaveCount(0);
});

