# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**vijf** is a Dutch flashcard app built on a five-box Leitner system. `web/` holds the PWA: a static site with no build step and no runtime dependencies (`web/package.json` exists only for the Playwright tests). `apple/` holds the native iOS and watchOS apps. `design/tokens.json` is shared by all of them.

- **[SPEC.md](SPEC.md)** says what the app does. Read it before changing features, and update it in the same change when behaviour changes.
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
- **Rendering:** each view is a function that returns an HTML string (`decksView`, `homeView` for one deck's boxes, `studyView`, `editView`, `summaryView`, `addView`, `backupView`). `render()` replaces `app.innerHTML` wholesale based on the module-level `view` variable, and falls back to `decks` if a deck view has no valid `deckId`. `launch()` picks the start screen. Any user text, including deck names, must go through `esc()` before being interpolated.
- **Events:** a single delegated click listener on `#app` dispatches on data attributes: `data-go="<view>"` (or `data-go="boxN"` to start a study session), `data-act="<action>"`, `data-deck="<deckId>"`, `data-del-deck="<deckId>"`, plus `#flip` to turn the card over. New interactions should hook into this listener instead of adding per-element listeners. Exceptions: the swipe gesture uses pointer listeners on `#app`, and the undo toast lives outside `#app` with its own listener.
- **State:** `state = { cards, nextId, decks, nextDeckId }` is persisted to `localStorage` under the key `leitner-dutch-v1`. Each card is `{ id, deckId, native, dutch, box (1–5), createdAt, reviewedAt }`; each deck is `{ id, name, createdAt }`. The open deck is the module-level `deckId`, and `inBox(n)` is scoped to it. Call `save()` after every mutation.
- **Migrations:** loaded data and restored back-ups both pass through `migrate()`. When the data shape changes, extend `migrate()` so old saves and old back-ups keep working, and never rename the storage key.
- **Leitner rules:** "I know it" moves a card up one box, capped at 5. "Not yet" leaves the card in its box and brings it back in the next round. Cards never move down. Box 5 sessions are read-only ("Next" only). The `session` object (`{ box, queue, retry, total, up, held, editing }`) lives only in memory; `session.queue[0]` is the current card. A session runs in rounds: `queue` is the rest of the round and `total` its size (the counter shows `total - queue.length + 1` of `total`), "Not yet" pushes onto `retry`, and `advance()` starts the next round from `retry` when `queue` runs out, and `editing` swaps the card for `editView`.
- **Undo:** `undoToast(msg, onUndo)` is the single undo slot, shared by deck and card deletes. A newer undo replaces the old one; call `clearUndo()` before replacing `state` wholesale (restore does).
- **Look:** colours come only from the CSS custom properties at the top of `index.html`, which mirror `design/tokens.json` (the vijf design system; `tests/look.spec.js` fails if they drift). Never write a literal colour in a rule; a fill pairs with its `on-*` token (`--danger` + `--on-danger`). Dark mode is the `prefers-color-scheme: dark` block.
- **UI language:** English only, short and plain. Only the words being learned are Dutch. A `<small>` subtitle is used only when it adds information (e.g. `Not yet<small>stays in box 1</small>`), never as a translation.

## Apple apps (`apple/`)

- **`VijfKit`** (Swift package) holds every rule and the data format, with Swift Testing tests that mirror `SPEC.md`: `Library` (decks, cards, answers, undo records), `StudySession` (rounds and the counter), `Backup` (lenient decode + `migrate`, mirroring the web app), `BulkImport`, `Tokens` (generated from `design/tokens.json`; `TokensTests` catches drift). Put new rules here, not in views.
- **`Vijf/`** is the SwiftUI iPhone app. `AppModel` (`@Observable`, `@MainActor`) owns the `Library`, saves it to Application Support as backup JSON after every change, and handles navigation (`Route`), the active `StudySession` and toasts with undo. Views only call `AppModel`. Colours come from `VJ` in `Theme.swift`; never use literal colours.
- **`Vijf.xcodeproj`** is hand-written and uses folder-synchronized groups: new files in `Vijf/` or `VijfTests/` are picked up automatically, so don't add per-file entries. `VijfTests/` tests `AppModel` (undo, launch, restore).
- **`VijfWatch/`** is the study-only watchOS app, embedded in the iPhone app. `WatchModel` keeps its own `Library` copy and study session; `VijfWatchApp.swift` holds the navigation (`WatchRoute`: deck list → `DeckBoxesView` → `WatchStudyView`); `PhoneLink` (watch) and `PhoneSync` (`Vijf/PhoneSync.swift`, phone) are the WatchConnectivity sides. The rules are in `VijfKit/Sync.swift` (tested in `SyncTests`): the phone sends its whole library as application context, the watch sends `Sync.Review`s (card + new box), both keep the higher box (`Sync.apply`, `Sync.merge`), and the watch re-sends `Sync.unsent` boxes when the phone's library arrives or it becomes reachable. Keep it idempotent: applying a review twice must change nothing.
- **`VijfComplication/`** is the watch-face complication: a WidgetKit extension embedded in the watch app (`Info.plist` holds only the extension point and is excluded from the synchronized group). It's a static launcher with no data (the five-bar `BarMark` from the app icon; colours from `VijfKit.Tokens`); showing counts would need an App Group shared with the watch app.
- In the simulators, `transferUserInfo` isn't delivered between paired simulators; `sendMessage` and application context are. Test sync with the paired iPhone 17 + Apple Watch Ultra simulators (`xcrun simctl list pairs`), with both apps running.
- Keep the backup JSON field names identical to the web app's (`cards`, `nextId`, `decks`, `nextDeckId`; card `id`, `deckId`, `native`, `dutch`, `box`, `createdAt`, `reviewedAt` in milliseconds).

## Service worker and the deploy

- `sw.js` precaches every asset. Page navigations are **network-first**, with the cache as the offline fallback. Everything else (icons, manifest) is **cache-first**.
- **Don't bump `CACHE` by hand.** The deploy workflow rewrites the `const CACHE = …` line to `'vijf-<short sha>'` on every deploy, so keep that line's format intact or the workflow's `grep` check fails. In the repo the value stays `'vijf-dev'`.
- The workflow publishes only `web/index.html`, `web/manifest.webmanifest`, `web/sw.js` and `web/icons/`. A new shipped file must be added to the workflow's copy step **and** to `ASSETS` in `sw.js`.
- All paths are relative (`./…`) because the site is served from the `/vijf/` subpath.
