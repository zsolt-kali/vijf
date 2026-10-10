// SPEC.md → Hearing the Dutch word
const { test, expect } = require('@playwright/test');
const { deck, card, data, open, study } = require('./helpers');

const sample = () => data(
  [deck(1, 'Start'), deck(2, 'Eten')],
  [card(1, 1, 'the house', 'het huis', 2), card(2, 1, 'the bread', 'het brood', 5)],
);

/* Replaces the browser's speech engine with a recorder, so tests can see what was said. */
async function fakeSpeech(page, voices = [{ lang: 'en-US', name: 'English' }, { lang: 'nl-NL', name: 'Xander' }]) {
  await page.addInitScript((list) => {
    window.__said = [];
    window.__cancels = 0;
    window.SpeechSynthesisUtterance = function (text) { this.text = text; };
    Object.defineProperty(window, 'speechSynthesis', {
      value: {
        getVoices: () => list,
        speak: (u) => window.__said.push({ text: u.text, lang: u.lang, voice: u.voice && u.voice.name }),
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

  expect(await said(page)).toEqual([{ text: 'het huis', lang: 'nl-NL', voice: 'Xander' }]);
  await expect(page.locator('#flip')).toHaveClass(/turned/);
});

test('without a Dutch voice it still asks for Dutch', async ({ page }) => {
  await fakeSpeech(page, [{ lang: 'en-US', name: 'English' }]);
  await open(page, sample());
  await study(page, 'Start', 2);
  await page.click('#flip');
  await speaker(page).click();
  expect(await said(page)).toEqual([{ text: 'het huis', lang: 'nl-NL' }]);
});

test('it works in box 5 review too', async ({ page }) => {
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
