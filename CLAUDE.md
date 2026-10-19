# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**vijf** is a Dutch flashcard app built on a five-box Leitner system. `web/` holds the PWA: a static site with no build step and no runtime dependencies (`web/package.json` exists only for the Playwright tests). `apple/` holds the native iOS and watchOS apps. `design/tokens.json` is shared by all of them.

- **[SPEC.md](SPEC.md)** says what the app does. Read it before changing features, and update it in the same change when behaviour changes.
- **[README.md](README.md) → "How vijf works"** is the plain explanation for people using the app. Whenever a change alters something a user would notice (rules, screens, wording, platforms), update that section in the same change, in the same plain style.
- **[design/](design/README.md)** is the design system: `tokens.json` (every colour, type style and size), `brand.md` (wording, colour meanings, shape, platforms) and `components/*.md`. Read `brand.md` and the relevant component note before any visual or wording change.
- **[DEVELOPMENT.md](DEVELOPMENT.md)** covers the workflow, the commands, how deploying works, and a decisions log. When making a new process or architecture decision, add an entry there.
- Feature ideas and bugs live in GitHub Issues (`gh issue …`).

## Commands

Web (run npm/npx from `web/`):

```bash
python3 -m http.server 8000 --directory web   # from the repo root: the app at http://localhost:8000
npm test                                      # all tests, Pixel 7 Chromium + iPhone 15 WebKit
npx playwright test tests/decks.spec.js -g "creating a deck" --project=android-chrome   # one test
```

A normal reload picks up edits to `index.html`. Changes to icons or the manifest need a hard reload, because those are served cache-first.

Apple (from `apple/`):

```bash
(cd VijfKit && swift test)                      # rules and data, on macOS, no simulator
xcodebuild test -project Vijf.xcodeproj -scheme Vijf -destination 'platform=iOS Simulator,name=iPhone 17'
python3 scripts/generate_tokens.py              # after changing a colour in design/tokens.json
```

## Web tests

- `web/tests/*.spec.js` are Playwright end-to-end tests, **one file per `SPEC.md` section**. When behaviour changes, update the matching test in the same change; when adding a feature, add tests for its acceptance criteria.
- Use the helpers in `tests/helpers.js`: `open(page, data(...))` seeds `localStorage` and loads the app, `saved(page)` reads the stored state back, and `swipeLeft()` drags a deck row.
- The service worker is blocked in tests (`serviceWorkers: 'block'`), so they always run against the current files.
- `tests/migration.spec.js` protects existing users' progress. Don't loosen it to make a change pass; fix `migrate()` instead.

## Branches and deploying

Work on a branch and open a pull request: a push to `main` that touches `web/` or `design/` deploys to GitHub Pages once the tests pass. CI has one workflow per app (`.github/workflows/web.yml`, …), each triggered only by its own folder or `design/`.

## Web app architecture (`web/`)

- **`index.html` is the entire app.** It holds the inline CSS, the markup shell (`<div id="app">`) and one IIFE of ES5-style JavaScript (`var`, `function`, no arrow functions or modules). Keep to that style.
- **Rendering:** each view is a function that returns an HTML string (`decksView`, `homeView` for one deck's boxes, `studyView`, `editView`, `summaryView` (or `doneView` when nothing is due in any deck), `roundView`, `browseView`, `addView`, `backupView`, `settingsView` (rows from `settingRow()`; `show.search` / `show.streak` hide the deck list's search field and streak), `newDeckView`; view `card` is `editView` for a card opened from search). The deck list's search keeps its text in the module-level `query`; typing redraws only `#list` (via `listHtml()`) so the field keeps focus, and `menuOpen` holds the ⋯ menu. `render()` replaces `app.innerHTML` wholesale based on the module-level `view` variable, and falls back to `decks` if a deck view has no valid `deckId`. `launch()` picks the start screen. Any user text, including deck names, must go through `esc()` before being interpolated.
- **Events:** a single delegated click listener on `#app` dispatches on data attributes: `data-go="<view>"` (or `data-go="boxN"` to start a study session), `data-act="<action>"`, `data-deck="<deckId>"`, `data-del-deck="<deckId>"`, `data-card="<cardId>"` (a search result), plus `#flip` to turn the card over. New interactions should hook into this listener instead of adding per-element listeners. Exceptions: the swipe gesture uses pointer listeners on `#app`, the search field an `input` listener on `#app`, Escape (closing the menu) and the arrow keys (browsing) a `keydown` listener on `document`, and the undo toast lives outside `#app` with its own listener.
- **State:** `state = { cards, nextId, decks, nextDeckId, doneDays }` is persisted to `localStorage` under the key `leitner-dutch-v1`. Each card is `{ id, deckId, native, dutch, box (1–5), createdAt, reviewedAt, seenAt }`; each deck is `{ id, name, createdAt }`. The open deck is the module-level `deckId`, and `inBox(n)` is scoped to it. Call `save()` after every mutation.
- **Migrations:** loaded data and restored back-ups both pass through `migrate()`. When the data shape changes, extend `migrate()` so old saves and old back-ups keep working, and never rename the storage key.
- **Leitner rules:** "I know it" moves a card up one box, capped at 5, and sets `reviewedAt`. "Not yet" moves it down one box (not below 1), or back to box 1 when the setting `missRule` is `'box1'` (`missBox()`; saved under `vijf-miss`, not in `state`); in box 1 it comes back in the next round, in boxes 2–5 it leaves the session. Both answers set `seenAt`. Spacing (`GAPS`, `dueDay(c)`): after "I know it" (`reviewedAt` on the same day as `seenAt`) a card is due again after its box's gap of 1, 2, 4, 8 or 16 days; after "Not yet" the next day. `dueIn(n)` is the box's cards due today, `nextIn(n)` says when a box with none due has its next. The `session` object (`{ box, queue, retry, total, round, up, held, editing }`) lives only in memory; `session.queue[0]` is the current card. A session runs in rounds: `queue` is the rest of the round and `total` its size (the counter shows `total - queue.length + 1` of `total`), "Not yet" in box 1 pushes onto `retry`. When `queue` runs out with cards in `retry`, `studyView` shows `roundView` (Go again → `nextRound()`, which also bumps `round`; Stop for today → the boxes); `editing` swaps the card for `editView`.
- **Browsing:** `browse = { ids, at }` (module-level, in memory) while the view is `browse`; `startBrowse()` orders the deck's cards with `browseOrder()` (box, then `createdAt`), `browseMove(±1)` steps. It never touches a card. The cog reuses the search edit form (view `card`), with `editFrom` saying where it returns (`'decks'` from search, `'browse'` from browsing); `deleteFound()` keeps `browse` in step. `cardHtml()` draws the study card for both study and browse.
- **Days in a row:** `save()` calls `markDone()`, which adds today (`dayKey()`, local "YYYY-MM-DD") to `state.doneDays` when there are cards and `dueAll()` is 0; `decksView` does too, for a day that passed while the app was open. `streak()` counts back with one forgiven miss per Monday–Sunday week (`mondayOf()`), `weekHtml()` draws the squares, `streakHtml()` the deck list's line. Mirrors VijfKit's `Streak`, tested with a fixed clock in `tests/streak.spec.js`.
- **Undo:** `undoToast(msg, onUndo)` is the single undo slot, shared by deck and card deletes. A newer undo replaces the old one; call `clearUndo()` before replacing `state` wholesale (restore does).
- **Look:** colours come only from the CSS custom properties at the top of `index.html`, which mirror `design/tokens.json` (the vijf design system; `tests/look.spec.js` fails if they drift). Never write a literal colour in a rule; a fill pairs with its `on-*` token (`--danger` + `--on-danger`). Dark mode is the `prefers-color-scheme: dark` block.
- **UI language:** English only, short and plain. Only the words being learned are Dutch. A `<small>` subtitle is used only when it adds information (e.g. `Not yet<small>stays in box 1</small>`), never as a translation.

## Apple apps (`apple/`)

- **`VijfKit`** (Swift package) holds every rule and the data format, with Swift Testing tests that mirror `SPEC.md`: `Library` (decks, cards, answers, spacing (`Card.dueDay`, `Card.gaps`), undo records), `StudySession` (rounds, the break between them, and the counter), `BrowseSession` (Browse cards: order, previous/next, delete and undo), `MissRule` (the "Not yet" setting), `Streak` (done days, days in a row, the week's squares; `Library.markDoneIfClear`), `Backup` (lenient decode + `migrate`, mirroring the web app), `BulkImport`, `Search` (matching cards across decks, ignoring case and accents), `Tokens` (generated from `design/tokens.json`; `TokensTests` catches drift). Put new rules here, not in views.
- **`Vijf/`** is the SwiftUI iPhone app. `AppModel` (`@Observable`, `@MainActor`) owns the `Library`, saves it to Application Support as backup JSON after every change, and handles navigation (`Route`), the active `StudySession` and toasts with undo. Views only call `AppModel`. Colours come from `VJ` in `Theme.swift`; never use literal colours.
- **`Vijf.xcodeproj`** is hand-written and uses folder-synchronized groups: new files in `Vijf/` or `VijfTests/` are picked up automatically, so don't add per-file entries. `VijfTests/` tests `AppModel` (undo, launch, restore).
- **`VijfWatch/`** is the study-only watchOS app, embedded in the iPhone app. `WatchModel` keeps its own `Library` copy and study session; `VijfWatchApp.swift` holds the navigation (`WatchRoute`: deck list → `DeckBoxesView` → `WatchStudyView`); `PhoneLink` (watch) and `PhoneSync` (`Vijf/PhoneSync.swift`, phone) are the WatchConnectivity sides. The rules are in `VijfKit/Sync.swift` (tested in `SyncTests`): the phone sends its whole library as application context, the watch sends a `Sync.Review` for every answer (card + box after it + time + known), and the latest answer to a card wins: box, `seenAt` and `reviewedAt` from whichever side answered last (`Sync.apply`, `Sync.merge`; not the higher box, since "Not yet" moves cards down), the phone's `MissRule` rides in the same application context (`Sync.missRule(fromContext:)`; the iPhone keeps it in `vijf.settings.json` next to its library, the watch the last one it got), the watch's `doneDays` ride with its answers and both sides keep the union (`Sync.addDoneDays`, `Sync.merge`), and the watch re-sends `Sync.unsent` answers when the phone's library arrives or it becomes reachable. Keep it idempotent: applying a review twice must change nothing.
- **`VijfComplication/`** is the watch-face complication: a WidgetKit extension embedded in the watch app (`Info.plist` holds only the extension point and is excluded from the synchronized group). It's a static launcher with no data (the five-bar `BarMark` from the app icon; colours from `VijfKit.Tokens`); showing counts would need an App Group shared with the watch app.
- **Version:** `scripts/stamp_version.sh` runs as the last build phase of `Vijf`, `VijfWatch` and `VijfComplication` (script sandboxing is off for those three, so it can read git). It writes `VijfCommit` and `VijfCommitDate` into each built Info.plist and sets `CFBundleVersion` to the commit count, so all three always match (the extension must match its app). `VijfKit.AppVersion` formats it for the Backup screen and the watch's deck list.
- In the simulators, `transferUserInfo` isn't delivered between paired simulators; `sendMessage` and application context are. Test sync with the paired iPhone 17 + Apple Watch Ultra simulators (`xcrun simctl list pairs`), with both apps running.
- Keep the backup JSON field names identical to the web app's (`cards`, `nextId`, `decks`, `nextDeckId`, `doneDays`; card `id`, `deckId`, `native`, `dutch`, `box`, `createdAt`, `reviewedAt`, `seenAt` in milliseconds).

## Service worker and the deploy

- `sw.js` precaches every asset. Page navigations are **network-first**, with the cache as the offline fallback. Everything else (icons, manifest) is **cache-first**.
- **Don't bump `CACHE` by hand.** The deploy workflow rewrites the `const CACHE = …` line to `'vijf-<short sha>'` on every deploy, so keep that line's format intact or the workflow's `grep` check fails. In the repo the value stays `'vijf-dev'`. The same goes for `var VERSION = 'dev';` in `index.html`: the workflow stamps it with the commit and its date, shown on the Backup screen.
- The workflow publishes only `web/index.html`, `web/manifest.webmanifest`, `web/sw.js` and `web/icons/`. A new shipped file must be added to the workflow's copy step **and** to `ASSETS` in `sw.js`.
- All paths are relative (`./…`) because the site is served from the `/vijf/` subpath.
