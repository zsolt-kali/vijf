# vijf — specification

What the app does today. Ideas and bugs go in GitHub Issues, not here.
Update this file in the same commit as any behaviour change.

## Purpose

Learn Dutch words with a five-box Leitner system. Single user, single device,
no account, works offline once loaded.

## Leitner rules

- Every new card starts in **box 1**.
- Studying is per box: the user picks a box and goes through all its cards in random order.
- **Ken ik** (I know it) moves the card up one box and removes it from the session.
- **Nog niet** (not yet) leaves the card in its box and puts it at the end of the session queue,
  so it comes back until the user knows it.
- Cards **never move down**.
- **Box 5** ("Geleerd") is the end. Studying box 5 is review only: one **Volgende** (next)
  button, no rating, cards stay in box 5.
- When the queue is empty, a summary shows how many cards moved up and how many "Nog niet"
  answers were given. The count is per answer, so a card answered "Nog niet" twice counts twice.

## Screens

| Screen | Contents |
|---|---|
| **Home** (Dozen) | Wordmark, plus a tally of cards in box 5 out of the total. Five box rows: number, Dutch name (Nieuw, Wankel, Op weg, Bijna, Geleerd), English subtitle, card count, and up to 20 tick marks. Empty boxes are greyed out, and a filled box 5 is highlighted yellow. Buttons: add words, all cards. With zero cards: an empty-state note and a button that loads the 12-word starter set. |
| **Study** | Box number and cards left. The card shows the native word on the front and the Dutch word on the back (yellow); tap to flip. Rating buttons are Nog niet / Ken ik, or Volgende in box 5. Tapping an empty box shows a toast instead of opening this screen. |
| **Summary** | "Ronde afgerond." with the moved-up and stayed counts, and a back button. |
| **Add** | Single add: native and Dutch fields, both required, saved to box 1. The form clears and refocuses so the next word can be typed right away. Bulk add: a textarea with one pair per line (see below). |
| **All cards** (Alles) | Every card sorted by box, then newest first. Each row shows the box, the Dutch word, the native word, and a × that deletes immediately without confirmation. Buttons: back-up, and wipe everything (needs a `confirm()`). |
| **Back-up** | A textarea holding the full state as JSON. Copy puts it on the clipboard; restore replaces the state with the pasted JSON. |

### Bulk import format

One card per line, native first and then Dutch. The separator can be `=`, `|`, tab or `;`,
with spaces around it allowed. If none of those appear, a comma is used. Lines with fewer
than two parts are skipped, and so are blank lines. Any parts after the second are ignored.

## Data

Stored in `localStorage` under the key **`leitner-dutch-v1`**:

```json
{
  "cards": [
    { "id": 1, "native": "the house", "dutch": "het huis",
      "box": 1, "createdAt": 1700000000000, "reviewedAt": null }
  ],
  "nextId": 2
}
```

- `box` is 1–5. `reviewedAt` is set when a card moves up and is not set on "Nog niet".
- The back-up text is exactly this JSON. Restore accepts any object with a `cards` array and
  rebuilds `nextId` if it's missing. There is no deeper validation.
- Changing the key or the card shape breaks existing data and old back-ups, so add a migration
  instead.

## Language and look

- Labels are Dutch with a small English subtitle; toasts are Dutch only.
- The palette is a fixed set of CSS variables (ink, paper, signal yellow, deep blue), with a
  square, bordered style. There is no dark mode.
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
