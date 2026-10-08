# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**vijf** is a Dutch flashcard app built on a five-box Leitner system. `web/` holds the PWA: a static site with no build step and no runtime dependencies (`web/package.json` exists only for the Playwright tests). `apple/` holds the native iOS and watchOS apps. `design/tokens.json` is shared by all of them.

- **[SPEC.md](SPEC.md)** says what the app does. Read it before changing features, and update it in the same change when behaviour changes.
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

## Service worker and the deploy

- `sw.js` precaches every asset. Page navigations are **network-first**, with the cache as the offline fallback. Everything else (icons, manifest) is **cache-first**.
- **Don't bump `CACHE` by hand.** The deploy workflow rewrites the `const CACHE = …` line to `'vijf-<short sha>'` on every deploy, so keep that line's format intact or the workflow's `grep` check fails. In the repo the value stays `'vijf-dev'`.
- The workflow publishes only `web/index.html`, `web/manifest.webmanifest`, `web/sw.js` and `web/icons/`. A new shipped file must be added to the workflow's copy step **and** to `ASSETS` in `sw.js`.
- All paths are relative (`./…`) because the site is served from the `/vijf/` subpath.
