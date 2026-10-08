# vijf — specification

What the app does today. Ideas and bugs go in GitHub Issues, not here.
Update this file in the same commit as any behaviour change.

## Purpose

Learn Dutch words with a five-box Leitner system. Single user, single device,
no account, works offline once loaded.

## Decks

- Cards are grouped into **decks**, one per topic. Each deck has its own five boxes.
- The user creates a deck by name. Names can't be empty and must be unique (case-insensitive).
- Every card belongs to exactly one deck.
- On launch the app shows the deck list. If there is exactly one deck, it opens straight into
  that deck instead.
- **Deleting:** swiping a deck row left on the deck list reveals a red **Delete**
  button on the right. Tapping it deletes the deck **and all its cards** immediately. A short
  swipe (under half the button width) springs back, a vertical move scrolls the page instead,
  and tapping anywhere else closes an open row.
- **Undo:** after a delete, a toast "Deck deleted · Undo" shows for 5 seconds.
  Tapping **Undo** restores the deck in its original position with all its
  cards and their boxes. Only the most recent delete can be undone: a second delete replaces
  the toast, and restoring a backup cancels it.
- Decks can't be renamed, and cards can't be moved between decks (yet).

## Leitner rules

- Every new card starts in **box 1** of the chosen deck.
- Studying is per box within a deck: the user picks a box and goes through all its cards in random order.
- **I know it** moves the card up one box and removes it from the session.
- **Not yet** leaves the card in its box and puts it at the end of the session queue,
  so it comes back until the user knows it.
- Cards **never move down**.
- **Box 5** ("Learned") is the end. Studying box 5 is review only: one **Next** button, no
  rating, cards stay in box 5.
- **Position counter:** the study screen shows the current card's position in the round as
  **3 / 12**. The total starts at the number of cards in the box. **Not yet** adds one to the
  total (the card comes round again), deleting the current card removes one, and undoing that
  delete adds it back, so the position never jumps.
- When the queue is empty, a summary shows how many cards moved up and how many "Not yet"
  answers were given. The count is per answer, so a card answered "Not yet" twice counts twice.

## Screens

| Screen | Contents |
|---|---|
| **Decks** | Wordmark and the number of decks. One row per deck, in creation order: name, card count, and learned (box 5) out of total. Empty decks are greyed out. Swiping a row left reveals its delete button (see Decks). A name field with **Create** creates a deck and opens it; Enter also works. With zero cards: a button that loads the 12-word starter set into a deck called **Start** and opens it. Always: a **Backup** button, so a backup can be restored on a fresh install. |
| **Deck** | A back button to the deck list and the deck name. Wordmark, plus a tally of this deck's cards in box 5 out of this deck's total. Five box rows: number, name (New, Shaky, Getting there, Nearly, Learned), card count, and up to 20 tick marks. Empty boxes are greyed out, and a filled box 5 is highlighted yellow. Button: add words. With zero cards in the deck: an empty-state note. |
| **Study** | Breadcrumb "Decks / *deck*" (both tappable) and the position counter (e.g. 3 / 12). The card shows the native word on the front ("Your language") and the Dutch word on the back ("Dutch", yellow); tap to flip. Below the card: **Not yet** (red, "stays in box n") and **I know it** (green, "→ box n+1"), or **Next** alone in box 5. The **cog** (⚙) sits inside the card, top-right, on both faces; tapping it opens the edit form (see Editing a card) without flipping the card. Tapping an empty box shows a toast instead of opening this screen. |
| **Summary** | Breadcrumb, "Round complete." with the moved-up and "Not yet" counts, and buttons back to the boxes or to another deck. |
| **Add** | A deck picker that defaults to the current deck; both single and bulk add use it, and the chosen deck becomes the current one. Single add: native and Dutch fields, both required, saved to box 1. The form clears and refocuses so the next word can be typed right away. Bulk add: a textarea with one pair per line (see below). |
| **Backup** | Opened from the deck list; the back button returns there. A textarea holding the full state as JSON. Copy puts it on the clipboard; restore replaces the state with the pasted JSON. |

### Bulk import format

One card per line, native first and then Dutch. The separator can be `=`, `|`, tab or `;`,
with spaces around it allowed. If none of those appear, a comma is used. Lines with fewer
than two parts are skipped, and so are blank lines. Any parts after the second are ignored.

## Editing a card

Cards are edited and deleted from the study screen. There is no list of all cards, so a card
is reached by studying its box.

- The **cog** (⚙) inside the study card replaces the card with an edit form: both meanings
  (*Your language*, *Dutch*) prefilled, **Cancel**, **Save**, and a red **Delete card**.
- **Save** updates both meanings and returns to the same card, still current in the session.
  The card keeps its box and `reviewedAt`. Both fields are required; an empty one shows a toast
  and nothing is saved. Enter in either field also saves.
- **Cancel** returns to the card unchanged.
- **Delete** removes the card immediately and moves on to the next card, or to the summary if it
  was the last one. A toast "Card deleted · Undo" shows for 5 seconds; undo puts the
  card back in its box and, if the session is still on screen, makes it the current card again.
  This shares the single undo slot with deck deletes (see Decks).
- There is no way to delete everything at once. Decks can be deleted one by one, and restoring
  a backup replaces all data.

## Data

Stored in `localStorage` under the key **`leitner-dutch-v1`**:

```json
{
  "cards": [
    { "id": 1, "deckId": 1, "native": "the house", "dutch": "het huis",
      "box": 1, "createdAt": 1700000000000, "reviewedAt": null }
  ],
  "nextId": 2,
  "decks": [
    { "id": 1, "name": "Start", "createdAt": 1700000000000 }
  ],
  "nextDeckId": 2
}
```

- `box` is 1–5. `reviewedAt` is set when a card moves up and is not set on "Not yet".
- The backup text is exactly this JSON. Restore accepts any object with a `cards` array.
  There is no deeper validation.
- Changing the key or the card shape breaks existing data and old backups, so add a migration
  instead.

### Migration

Saved data and restored backups both go through `migrate()` in `index.html`:

- A missing `decks`, `nextId` or `nextDeckId` is filled in.
- Any card without a valid `deckId` goes into a deck called **Start**, which is created if it
  doesn't exist. The card keeps its box. This is how data and backups from before decks
  existed are carried over without losing progress.

## Language and look

- The interface is in **English** only, with short, plain wording. Only the words being learned are Dutch.
  Small subtitles appear only where they add information (e.g. "stays in box 1").
- Colours, type and sizes come from the **vijf design system** (`design/tokens.json`; see
  `design/README.md`). Square corners, 1.5px outlines, no shadows.
- **Dark mode follows the device setting** (`prefers-color-scheme`), including the browser bar
  colour (`theme-color`). Every colour has a light and a dark value.
- Colour meanings: yellow (`signal`) = learned, the back of the card; blue (`deep`) = progress
  ticks and focus; red (`danger`) = Not yet and deleting; green (`success`) = I know it.
  Red and green always carry their words, so they never rely on colour alone.
- `prefers-reduced-motion` disables the card flip and box animations.

## Platform

- An installable PWA (`manifest.webmanifest`, standalone display, icons in `icons/`).
- Offline support comes from a service worker (`sw.js`). The page is network-first, so an
  online phone always gets the latest version; icons and the manifest are cache-first.
- Deployed to GitHub Pages under `/vijf/` by a GitHub Actions workflow, which stamps the cache
  version with the commit ID. All paths are relative.

## Non-goals

- No sync between devices, no accounts, no server.
- No spaced-repetition scheduling by date. The user decides which box to study.
- Cards never get demoted.
