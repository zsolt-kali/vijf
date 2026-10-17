# vijf — specification

What the apps do today. Ideas and bugs go in GitHub Issues, not here.
Update this file in the same commit as any behaviour change.

The rules here apply to every app: the **web app** (`web/`), the **iPhone app** and the
**Apple Watch app** (both in `apple/`).
Where an app differs, the **Platforms** section says so.

## Purpose

Learn Dutch words with a five-box Leitner system. Single user, single device,
no account, works offline once loaded.

## Decks

- Cards are grouped into **decks**, one per topic. Each deck has its own five boxes.
- The user creates a deck by name (**New deck** in the deck list's **⋯** menu; with no decks yet,
  the name field is on the deck list itself). Names can't be empty and must be unique
  (case-insensitive).
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
- Studying is per box within a deck: the user picks a box and goes through all its cards due
  today in random order.
- **Spacing:** each box has its own gap, counted in days from the day the card was last
  answered; the day starts at local midnight.

  | Box | Comes up |
  |---|---|
  | 1 | every day |
  | 2 | every 2 days |
  | 3 | every 4 days |
  | 4 | every 8 days |
  | 5 | every 16 days |

  After **I know it** the card waits the gap of its (new) box: a card moved from box 1 to box 2
  on Monday is due again on Wednesday. After **Not yet** it is due again the next day, whatever
  its box. A big box can be studied in parts: reopening it later shows only the cards still due.
  Within one session nothing changes: in box 1, "Not yet" cards still come back in the next round. Cards
  never answered (no `seenAt`, including data from before the daily rule) are due.
- **I know it** moves the card up one box and removes it from the session. In box 5 the card
  stays in box 5.
- **Not yet** moves the card **down one box** (box 1 stays in box 1), and it is due again the
  next day. A setting can make it **send the card back to box 1** instead (classic Leitner; see
  Settings below); the button's subtitle and the summary say where the card goes. In box 1 it comes back in the next round (see below) until the user knows it. In
  boxes 2–5 it leaves the session, because another round would only move it straight back up.
- **Box 5** ("Learned") works like the others: **I know it** keeps the card in box 5,
  **Not yet** moves it back to box 4.
- **Rounds:** round 1 shows every card in the box that is due today, in random order. In box 1,
  when a round ends with cards answered **Not yet**, a short screen says so ("Round 1 done.",
  "11 not yet.") with **Go again** and **Stop for today**. **Go again** brings those cards back
  as the next round, in the order they were answered; **Stop for today** returns to the boxes,
  and the missed cards come back tomorrow. When a round ends with every card known, the summary
  shows. Boxes 2–5 have a single round.
- **Position counter:** the study screen shows the current card's position in the round as
  **3 / 12**, where 12 is the size of the round. Every answer moves the position forward by one;
  **no answer ever changes the total**. A new round starts at 1 with its own total (e.g. 1 / 3).
  Deleting the current card removes it from the round (the total drops by one, the position
  stays); undoing the delete adds it back.
- When the queue is empty, a summary shows how many cards moved up and how many "Not yet"
  answers were given ("Moved up to box 2: 5. Not yet: 3."). The count is per answer, so a card
  answered "Not yet" twice counts twice. In boxes 2–5 it says where missed cards went
  ("Moved up to box 4: 6. Back to box 2: 1."), and box 5 "Stayed in box 5: 4. Back to box 4: 1."

## Screens

| Screen | Contents |
|---|---|
| **Decks** | Wordmark and a **⋯** button (no deck count). The ⋯ menu holds **New deck**, **Settings** and **Backup**; tapping anywhere else (or Escape) closes it. Below the header: the search field (see Search), then one row per deck, in creation order: name, how many cards are left today, and learned (box 5) out of total. The line under the name counts the deck's cards due today in all five boxes ("8 left today"), says "Done for today" when none are left, and "0 cards" for an empty deck. There is no total across decks. Empty decks are greyed out. Swiping a row left reveals its delete button (see Decks). With zero decks there is no search field; instead an empty-state note and a name field with **Create**, which creates a deck and opens it (Enter also works). With zero cards: a button that loads the 12-word starter set into a deck called **Start** and opens it. Backup stays in the menu even with no decks, so a backup can be restored on a fresh install. |
| **New deck** | Opened from the ⋯ menu; the back button returns to the deck list. A name field (focused) and **Create**, which creates the deck and opens it; Enter also works. |
| **Deck** | A back button to the deck list and the deck name. Wordmark, plus a tally of this deck's cards in box 5 out of this deck's total. Five box rows: number, name (New, Shaky, Getting there, Nearly, Learned), card count, and up to 20 tick marks. When only some of a box's cards are due, a line under the name says how many ("8 left today"); when none are, it says when the next one comes up ("Next tomorrow", "Next in 3 days"), the box is greyed out like an empty one (it keeps its count, loses its ticks) and tapping it shows that line as a toast. Empty boxes are greyed out, and a filled box 5 is highlighted yellow. Below the button, a note explains the rules, including that **Not yet** moves a card down one box and the gaps (every day, 2 days, then 4, 8 and 16). Buttons: **Add words** (fill) and **Browse cards** (outlined; greyed out for a deck without cards), see Browsing a deck. With zero cards in the deck: an empty-state note. |
| **Study** | Breadcrumb "Decks / *deck*" (both tappable) and the position counter (e.g. 3 / 12). The card shows the native word on the front ("Your language") and the Dutch word on the back ("Dutch", yellow); tap to flip. Below the card: **Not yet** (red, "back to box n−1", or "stays in box 1") and **I know it** (green, "→ box n+1", or "stays in box 5"). The **cog** (⚙) sits inside the card, top-right, on both faces; tapping it opens the edit form (see Editing a card) without flipping the card. On the back, a **speaker** sits just left of the cog (see Hearing the Dutch word). Tapping an empty box shows a toast instead of opening this screen. |
| **Browse** | See Browsing a deck: an ink band (breadcrumb, **BROWSING**, the position), the card with its box, **← Previous** / **Next →** (Done on the last card). |
| **Round done** | Box 1 only, between rounds: breadcrumb, "Round *n* done.", "*n* not yet.", and **Go again** (fill) / **Stop for today**. |
| **Summary** | Breadcrumb, "Round complete." with the moved-up and "Not yet" counts, and buttons back to the boxes or to another deck. |
| **Add** | A deck picker that defaults to the current deck; both single and bulk add use it, and the chosen deck becomes the current one. Single add: native and Dutch fields, both required, saved to box 1. The form clears and refocuses so the next word can be typed right away. Bulk add: a textarea with one pair per line (see below). |
| **Settings** | Opened from the deck list's ⋯ menu; the back button returns there. **When you don't know a card:** "Move it down one box" ("As now", the default) or "Send it back to box 1" ("Classic Leitner"); the chosen one says "In use", and a note says the card comes back tomorrow either way and box 1 cards stay in box 1. Web: below it, speed and voice for reading Dutch aloud (see Hearing the Dutch word), where the browser can speak. Saved on the device, not in the cards or backups: web `vijf-miss` in `localStorage`; iPhone a settings file next to its library, sent to the watch (see Apple Watch → Sync). |
| **Backup** | Opened from the deck list's ⋯ menu; the back button returns there. A textarea holding the full state as JSON. Copy puts it on the clipboard; restore replaces the state with the pasted JSON. At the bottom, the version: "Version 3116643 · 15 Oct 2026", the commit the app was built from and its date ("Version dev" when not deployed). |

### Bulk import format

One card per line, native first and then Dutch. The separator can be `=`, `|`, tab or `;`,
with spaces around it allowed. If none of those appear, a comma is used. Lines with fewer
than two parts are skipped, and so are blank lines. Any parts after the second are ignored.

## Search

The deck list has a search field, **Search all cards**, above the decks whenever there is at
least one deck.

- It matches either side of a card (your language or Dutch), anywhere in the word, ignoring case
  and accents: "cafe" finds "café", "DRUK" finds "druk". Spaces around the text are ignored, and
  blank text shows the decks.
- While there is text, the deck rows are replaced by the matching cards from every deck, in deck
  order and then in the order they were added. Above them, the count ("3 cards", "1 card", or
  "No cards match"). Each result shows the word in your language, the Dutch word and the deck
  name, and the card's box number on the right (yellow for box 5). The matching part is
  underlined in blue on whichever side it was found.
- A **×** button in the field clears it and brings the decks back.
- Tapping a result opens that card's edit form (see Editing a card). Save, Cancel and the back
  button (**← Search**) return to the results, with the search text kept. **Delete card**
  removes it with the same 5-second undo.
- Opening or creating a deck clears the search.

## Hearing the Dutch word

- The back of the study card (the Dutch side) has a **speaker** button, just left of the cog.
  Tapping it reads the Dutch word aloud with the device's own Dutch voice, and does not flip the
  card. Tapping it again starts the word over.
- Nothing plays by itself. Answering or leaving the screen stops a word being read.
- It works in every box. It uses the device's built-in voices, so it needs no
  network where the device has a Dutch voice.
- Web: the browser's speech (`speechSynthesis`), asking for Dutch (`nl-NL`). Without speech
  support in the browser there is no speaker, and Settings has no voice or speed.
- **Voice and speed (web only):** on the Settings screen, in the deck list's ⋯ menu. **Speed:** Slow, Normal or Fast. **Voice:**
  a row for each Dutch voice the browser lists, with its name and "Netherlands" or "Belgium"; the
  one in use says "In use". Tapping a speed or a voice chooses it and reads "Goedemorgen". With no
  Dutch voice it says so; a note gives the Mac path for downloading more (System Settings →
  Accessibility → Read & Speak → System voice → Manage Voices → Dutch).
- Without a choice, or when the chosen voice is no longer listed, the first voice from the
  Netherlands is used, else any Dutch voice (browsers often list a Belgian one first). The choice
  is saved on the device only (`vijf-voice` in `localStorage`, not part of the cards or backups),
  because each device has its own voices.

## Browsing a deck

- **Browse cards**, on a deck's boxes screen next to **Add words**, goes through all the deck's
  cards one at a time, **without answering**: no box changes and `seenAt` stays as it is, so
  today's counts don't change either. There is no mode: leaving the screen ends it.
- Order: box 1 first, then the order the cards were added.
- The top is an **ink band**: the breadcrumb, **BROWSING** (in `on-ink-accent`) and the
  position "3 / 12".
- The card is the study card: tap to flip; both footers show the card's box on the right ("Box
  3"); the back says "Tap to flip back". The cog edits or deletes the card (web and iPhone)
  and the speaker reads the Dutch word.
- **← Previous** (greyed out on the first card) and **Next →**. On the last card, Next becomes
  **Done**, which returns to the deck's boxes. Web: the ← and → keys do the same.
- Deleting the shown card shows the next one (the previous one if it was the last); undo puts it
  back and shows it again. Deleting the deck's only card ends browsing.
- A deck without cards can't be browsed.
- Watch: a **Browse cards** row under the five boxes (not shown for a deck without cards); the
  card with Previous / Next (Done) under it and the position top-right; no editing.

## Editing a card

Cards are edited and deleted from the study screen, or from a search result (see Search).
There is no list of all cards.

- The **cog** (⚙) inside the study card replaces the card with an edit form: both meanings
  (*Your language*, *Dutch*) prefilled, **Cancel**, **Save**, and a red **Delete card**.
- **Save** updates both meanings and returns to the same card, still current in the session.
  The card keeps its box and `reviewedAt`. Both fields are required; an empty one shows a toast
  and nothing is saved. Enter in either field also saves.
- **Cancel** returns to the card unchanged.
- **Delete** removes the card immediately and moves on to the next card, or, if it was the last
  one of the round, to the round-done screen or the summary. A toast "Card deleted · Undo" shows for 5 seconds; undo puts the
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
      "box": 1, "createdAt": 1700000000000, "reviewedAt": null, "seenAt": null }
  ],
  "nextId": 2,
  "decks": [
    { "id": 1, "name": "Start", "createdAt": 1700000000000 }
  ],
  "nextDeckId": 2
}
```

- `box` is 1–5. `reviewedAt` is set on "I know it" (box 5 included) and not on "Not yet".
  `seenAt` is set on every answer; the gaps count from its day. The last answer was "I know it"
  when `reviewedAt` falls on the same day as `seenAt` (older versions set the two a moment
  apart), otherwise "Not yet". A missing or null `seenAt` (never answered, or data from before
  the daily rule) means the card is due, so no migration step is needed.
- The backup text is exactly this JSON. Restore accepts any object with a `cards` array.
  There is no deeper validation.
- Changing the key or the card shape breaks existing data and old backups, so add a migration
  instead.

### Migration

Saved data and restored backups both go through `migrate()` in `web/index.html`:

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

## Platforms

### Web (`web/`)

- An installable PWA (`manifest.webmanifest`, standalone display, icons in `icons/`).
- Offline support comes from a service worker (`sw.js`). The page is network-first, so an
  online phone always gets the latest version; icons and the manifest are cache-first.
- Deployed to GitHub Pages under `/vijf/` by a GitHub Actions workflow, which stamps the cache
  version with the commit ID. All paths are relative.

### iPhone (`apple/`)

- A native SwiftUI app, iOS 18 and later, iPhone, portrait. Same screens, rules, wording and
  colours as the web app; the rules and data live in the `VijfKit` package, shared with the
  planned watch app.
- Data is saved on the device as the same JSON as the web app's backup. **Backup** shows that
  text with **Copy** and **Share**, and restores from pasted text, so a backup moves between the
  web app and the iPhone app in either direction (including backups from before decks existed).
- Platform conventions where they help: the system back button and title instead of the web
  app's breadcrumb (the position counter sits top-right), the system swipe action to delete a
  deck, add words as a sheet, the system menu for **⋯**, **New deck** as a system prompt with a
  name field (Cancel / Create) instead of a screen, and a search result's edit form as a sheet.
- Differences from the web app: on the Add sheet, picking another deck adds the words there
  but doesn't switch to that deck; the cog is the system "gearshape" symbol and the speaker
  "speaker.wave.2". The speaker plays even with the ring switch on silent, and lowers music
  instead of stopping it.

### Apple Watch (`apple/VijfWatch`)

- **Study only**, watchOS 11 and later. It comes with the iPhone app and has no editing,
  adding, deleting or backup; that happens on the phone.
- **Screens**, in the same order as on the phone: deck → boxes → study.
  - **Decks:** below the list, the version, the same as the iPhone's Backup screen shows
    (both are built together). Each deck with, as on the phone, "8 left today" or "Done for today", and learned (box 5) out of total; decks without
    cards are greyed out. With exactly one deck the watch opens straight into it.
  - **Boxes:** the deck's five boxes (New, Shaky, Getting there, Nearly, Learned) with card
    counts and, as on the phone, "8 left today" or "Next in 3 days" under the name; empty boxes
    and boxes with nothing due are greyed out and can't be opened. A filled box 5 has a yellow number.
    Under them, **Browse cards** (see Browsing a deck).
  - **Study:** the position counter top-right, the card filling the screen (tap to flip; Dutch
    on yellow), and **Not yet** (red) / **I know it** (green) side by side, in every box.
    Text too long for the card scrolls (Digital Crown or swipe) instead of being cut off; a new
    card or a flip starts at the top.
    Rounds, the counter and the summary follow the Leitner rules above.
  - With no decks yet, the watch asks you to open vijf on the iPhone.
  - If a deck you have open is deleted on the phone, the watch goes back to the deck list.
- **Complication:** vijf can be added to a watch face and opens the app when tapped. It shows the
  app icon's mark, five bars narrowing downward (one per box) with the top bar highlighted:
  circular (the mark), corner (the mark, labelled "vijf"), rectangular (the mark beside
  "vijf / Study Dutch") and inline (the text "vijf"). On tinted faces the top bar takes the
  face's accent colour and the rest are white; on full-colour faces the top bar is vijf yellow
  and the rest light, as in the icon. It shows no counts.
- Always dark (watchOS), using the dark value of every colour token.
- **Offline:** the watch keeps its own copy of the decks, so it works without the phone nearby.
- **Sync** (WatchConnectivity):
  - The phone is the source of truth for decks, words and deletions. It sends its whole library
    when it starts, after every change, and whenever it comes to the front; the watch replaces
    its copy with it, except that a card answered later on the watch keeps the watch's box,
    `seenAt` and `reviewedAt`. Each send
    carries its time, so it is delivered even when nothing changed.
  - The iPhone's **Backup** screen shows how the last send went: "Watch: sent 18:52", or
    "Watch: not sent." with the reason (in red). Nothing is shown when no watch is paired.
  - The phone's **"Not yet" setting** (Settings) travels with the library; the watch keeps the last
    one it got and answers by it, so a card missed on the watch goes where it would on the phone.
    Changing the setting sends it straight away.
  - Each answer on the watch (**I know it** or **Not yet**) goes to the phone with the card's box
    after it, the time, and whether it was **I know it**: straight away when the phone is
    reachable, otherwise queued until it is. The **latest answer wins**: the phone takes it only
    if it is later than the card's own `seenAt`, so a card answered on the watch isn't due on
    the phone before its time.
  - Whenever the phone's library arrives, the phone becomes reachable, or the watch app comes to
    the front, the watch re-reads the phone's latest library and re-sends
    every answer later than the phone's, so an answer can't get lost. Applying an answer twice,
    or an older one, changes nothing.
  - The latest answer wins rather than the higher box, because **Not yet** moves a card down a
    box; keeping the higher box would undo that.

## Non-goals

- No sync between devices, no accounts, no server. (The one exception: an iPhone and its own
  Apple Watch sync directly, see Platforms.)
- No spaced-repetition scheduling by date. The user decides which box to study.
- Cards never get demoted.
