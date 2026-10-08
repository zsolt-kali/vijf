# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**vijf** is a Dutch flashcard PWA built on a five-box Leitner system. The app is a static site with no build step and no runtime dependencies. `package.json` exists only for the Playwright tests.

- **[SPEC.md](SPEC.md)** says what the app does. Read it before changing features, and update it in the same change when behaviour changes.
- **[DEVELOPMENT.md](DEVELOPMENT.md)** covers the workflow, the commands, how deploying works, and a decisions log. When making a new process or architecture decision, add an entry there.
- Feature ideas and bugs live in GitHub Issues (`gh issue …`).

## Commands

```bash
python3 -m http.server 8000          # run the app at http://localhost:8000
npm test                             # all tests, Pixel 7 Chromium + iPhone 15 WebKit
npx playwright test tests/decks.spec.js -g "creating a deck" --project=android-chrome   # one test
```

A normal reload picks up edits to `index.html`. Changes to icons or the manifest need a hard reload, because those are served cache-first.

## Tests

- `tests/*.spec.js` are Playwright end-to-end tests, **one file per `SPEC.md` section**. When behaviour changes, update the matching test in the same change; when adding a feature, add tests for its acceptance criteria.
- Use the helpers in `tests/helpers.js`: `open(page, data(...))` seeds `localStorage` and loads the app, `saved(page)` reads the stored state back, and `swipeLeft()` drags a deck row.
- The service worker is blocked in tests (`serviceWorkers: 'block'`), so they always run against the current files.
- `tests/migration.spec.js` protects existing users' progress. Don't loosen it to make a change pass; fix `migrate()` instead.

## Branches and deploying

Work on a branch: every push to `main` deploys to GitHub Pages once the tests pass. CI (`.github/workflows/deploy.yml`) runs the tests on every push and pull request.

## Architecture

- **`index.html` is the entire app.** It holds the inline CSS, the markup shell (`<div id="app">`) and one IIFE of ES5-style JavaScript (`var`, `function`, no arrow functions or modules). Keep to that style.
- **Rendering:** each view is a function that returns an HTML string (`decksView`, `homeView` for one deck's boxes, `studyView`, `editView`, `summaryView`, `addView`, `backupView`). `render()` replaces `app.innerHTML` wholesale based on the module-level `view` variable, and falls back to `decks` if a deck view has no valid `deckId`. `launch()` picks the start screen. Any user text, including deck names, must go through `esc()` before being interpolated.
- **Events:** a single delegated click listener on `#app` dispatches on data attributes: `data-go="<view>"` (or `data-go="boxN"` to start a study session), `data-act="<action>"`, `data-deck="<deckId>"`, `data-del-deck="<deckId>"`, plus `#flip` to turn the card over. New interactions should hook into this listener instead of adding per-element listeners. Exceptions: the swipe gesture uses pointer listeners on `#app`, and the undo toast lives outside `#app` with its own listener.
- **State:** `state = { cards, nextId, decks, nextDeckId }` is persisted to `localStorage` under the key `leitner-dutch-v1`. Each card is `{ id, deckId, native, dutch, box (1–5), createdAt, reviewedAt }`; each deck is `{ id, name, createdAt }`. The open deck is the module-level `deckId`, and `inBox(n)` is scoped to it. Call `save()` after every mutation.
- **Migrations:** loaded data and restored back-ups both pass through `migrate()`. When the data shape changes, extend `migrate()` so old saves and old back-ups keep working, and never rename the storage key.
- **Leitner rules:** "I know it" moves a card up one box, capped at 5. "Not yet" re-queues the card at the end of the current session and leaves it in its box. Cards never move down. Box 5 sessions are read-only ("Next" only). The `session` object (`{ box, queue, total, up, held, editing }`) lives only in memory; `session.queue[0]` is the current card, the counter shows `total - queue.length + 1` of `total`, and `editing` swaps the card for `editView`.
- **Undo:** `undoToast(msg, onUndo)` is the single undo slot, shared by deck and card deletes. A newer undo replaces the old one; call `clearUndo()` before replacing `state` wholesale (restore does).
- **UI language:** English only, short and plain. Only the words being learned are Dutch. A `<small>` subtitle is used only when it adds information (e.g. `Not yet<small>stays in box 1</small>`), never as a translation.

## Service worker and the deploy

- `sw.js` precaches every asset. Page navigations are **network-first**, with the cache as the offline fallback. Everything else (icons, manifest) is **cache-first**.
- **Don't bump `CACHE` by hand.** The deploy workflow rewrites the `const CACHE = …` line to `'vijf-<short sha>'` on every deploy, so keep that line's format intact or the workflow's `grep` check fails. In the repo the value stays `'vijf-dev'`.
- The workflow publishes only `index.html`, `manifest.webmanifest`, `sw.js` and `icons/`. A new shipped file must be added to the workflow's copy step **and** to `ASSETS` in `sw.js`.
- All paths are relative (`./…`) because the site is served from the `/vijf/` subpath.
