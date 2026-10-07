// Shared helpers: seed saved data, read it back, and find things on screen.
const KEY = 'leitner-dutch-v1';

function deck(id, name) {
  return { id, name, createdAt: id };
}
function card(id, deckId, native, dutch, box = 1) {
  return { id, deckId, native, dutch, box, createdAt: 1, reviewedAt: null };
}
function data(decks, cards) {
  return {
    cards,
    nextId: Math.max(0, ...cards.map((c) => c.id)) + 1,
    decks,
    nextDeckId: Math.max(0, ...decks.map((d) => d.id)) + 1,
  };
}

/* Opens the app. With `saved`, that object is written to localStorage first,
   as if a previous session had left it there. */
async function open(page, saved) {
  await page.goto('/');
  if (saved !== undefined) {
    await page.evaluate(([k, s]) => localStorage.setItem(k, JSON.stringify(s)), [KEY, saved]);
    await page.reload();
  }
}

async function saved(page) {
  return page.evaluate((k) => JSON.parse(localStorage.getItem(k)), KEY);
}

function deckRow(page, name) {
  return page.locator('.slot--deck').filter({ has: page.locator('.lbl', { hasText: name }) });
}

function toast(page) {
  return page.locator('.toast').last();
}

/* Drags a deck row to the left by `distance` pixels, like a finger swipe. */
async function swipeLeft(page, row, distance = 130) {
  const box = await row.boundingBox();
  const x = box.x + box.width - 30;
  const y = box.y + box.height / 2;
  await page.mouse.move(x, y);
  await page.mouse.down();
  for (let i = 1; i <= 8; i++) await page.mouse.move(x - (distance * i) / 8, y);
  await page.mouse.up();
}

module.exports = { KEY, deck, card, data, open, saved, deckRow, toast, swipeLeft };
