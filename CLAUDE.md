# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**vijf** is a Dutch flashcard PWA built on a five-box Leitner system. It's a static site with no build step, no dependencies, no package manager and no tests. It's deployed to GitHub Pages by `.github/workflows/deploy.yml` on every push to `main`.

The app's behaviour is specified in [SPEC.md](SPEC.md). Read it before changing features, and update it in the same change when behaviour changes. Feature ideas and bugs live in GitHub Issues, not in the spec.

## Running locally

The service worker only registers over HTTP(S), so serve the folder instead of opening the file directly:

```bash
python3 -m http.server 8000
```

Then open http://localhost:8000/. A normal reload picks up edits to `index.html`. Changes to icons or the manifest need a hard reload, because those are served cache-first.

## Architecture

- **`index.html` is the entire app.** It holds the inline CSS, the markup shell (`<div id="app">`) and one IIFE of ES5-style JavaScript (`var`, `function`, no arrow functions or modules). Keep to that style.
- **Rendering:** each view is a function that returns an HTML string (`decksView`, `homeView` for one deck's boxes, `studyView`, `summaryView`, `addView`, `listView`, `backupView`). `render()` replaces `app.innerHTML` wholesale based on the module-level `view` variable, and falls back to `decks` if a deck view has no valid `deckId`. `launch()` picks the start screen. Any user text, including deck names, must go through `esc()` before being interpolated.
- **Events:** a single delegated click listener on `#app` dispatches on data attributes: `data-go="<view>"` (or `data-go="boxN"` to start a study session), `data-act="<action>"`, `data-del="<cardId>"`, `data-deck="<deckId>"`, plus `#flip` to turn the card over. New interactions should hook into this listener instead of adding per-element listeners.
- **State:** `state = { cards, nextId, decks, nextDeckId }` is persisted to `localStorage` under the key `leitner-dutch-v1`. Each card is `{ id, deckId, native, dutch, box (1–5), createdAt, reviewedAt }`; each deck is `{ id, name, createdAt }`. The open deck is the module-level `deckId`, and `inBox(n)` is scoped to it. Call `save()` after every mutation.
- **Migrations:** loaded data and restored back-ups both pass through `migrate()`. When the data shape changes, extend `migrate()` so old saves and old back-ups keep working, and never rename the storage key.
- **Leitner rules:** "Ken ik" moves a card up one box, capped at 5. "Nog niet" re-queues the card at the end of the current session and leaves it in its box. Cards never move down. Box 5 sessions are read-only ("Volgende" only). The `session` object (`{ box, queue, up, held }`) lives only in memory.
- **UI language:** labels are Dutch with an English `<small>` subtitle, e.g. `Woord toevoegen<small>add words</small>`. Toasts are in Dutch.

## Service worker / deploying changes

- `sw.js` precaches every asset. Page navigations are **network-first**, with the cache as the offline fallback. Everything else (icons, manifest) is **cache-first**.
- **Don't bump `CACHE` by hand.** The deploy workflow rewrites the `const CACHE = …` line to `'vijf-<short sha>'` on every deploy, so keep that line's format intact or the workflow's `grep` check fails. In the repo the value stays `'vijf-dev'`.
- The workflow publishes only `index.html`, `manifest.webmanifest`, `sw.js` and `icons/`. A new shipped file must be added to the workflow's copy step **and** to `ASSETS` in `sw.js`.
- All paths are relative (`./…`) because the site is served from the `/vijf/` subpath.
