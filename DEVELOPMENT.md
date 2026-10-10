# Development

How vijf is built, tested and shipped, and why it's set up this way.
What the app *does* is in [SPEC.md](SPEC.md); planned work is in GitHub Issues.

## Workflow

1. **Issue.** Describe the feature or bug in a GitHub issue, with acceptance criteria.
2. **Branch.** Work on a branch, never directly on `main`, because every push to `main` can go live.
3. **Build and test locally** (commands below). Update `SPEC.md` and the tests in the same change
   whenever behaviour changes.
4. **Pull request** into `main`, with `Closes #N` in its description. One PR at a time: no PRs
   stacked on other unmerged branches (they merge into that branch, not `main`). CI runs the tests for the app the change
   touches; nothing deploys from a pull request.
5. **Merge to `main`.** CI runs the tests again and, for the web app, deploys if they pass. Phones
   get the update the next time the app is opened online.

## Layout

```
web/       the PWA and its Playwright tests (its own package.json)
apple/     the iOS and watchOS apps
design/    tokens.json, shared by every app
```

## Web commands

Run these from `web/`. One-time setup (needs Node.js LTS from nodejs.org):

```bash
npm install
npx playwright install chromium webkit
```

Run the app locally at http://localhost:8000 (from the repo root):

```bash
python3 -m http.server 8000 --directory web
```

Run all tests (they start their own server on port 4173):

```bash
npm test
```

Run one file, one test by name, or one browser:

```bash
npx playwright test tests/decks.spec.js
npx playwright test -g "undo restores the deck"
npx playwright test --project=iphone-safari
```

Open the HTML report after a failed run with `npm run test:report`. In CI, the report is
attached to the failed run as the `playwright-report` artifact.

## Apple commands

Needs Xcode (Mac App Store). From `apple/`:

```bash
(cd VijfKit && swift test)
xcodebuild test -project Vijf.xcodeproj -scheme Vijf -destination 'platform=iOS Simulator,name=iPhone 17'
```

Or open `apple/Vijf.xcodeproj` in Xcode and press ⌘R (run) or ⌘U (test). The **VijfWatch**
scheme runs the watch app on a watch simulator; running **Vijf** on a phone or simulator with a
paired watch installs both. To install on your own
iPhone: select the Vijf target → Signing & Capabilities → Team = your Apple ID, then run with the
phone connected. With a free Apple ID the install expires after 7 days.

After changing a colour in `design/tokens.json`, run `python3 apple/scripts/generate_tokens.py`
from the repo root; the web app's CSS needs the same change (both are checked by tests).

## CI and deploying

Each app has its own workflow, which runs only when that app's folder or `design/` changes:

- **`.github/workflows/web.yml`**: **test** runs on every pull request and every push to `main`
  (15-minute limit). **deploy** runs only for pushes to `main`, after **test** passes. It copies
  `web/index.html`, `web/manifest.webmanifest`, `web/sw.js` and `web/icons/` to a folder, stamps
  the service worker's `CACHE` with the commit ID, and publishes that folder to GitHub Pages.

- **`.github/workflows/apple.yml`**: on a macOS runner with the latest stable Xcode, runs the
  `VijfKit` tests, then builds the iPhone app and runs its tests on a simulator (30-minute limit).
  It doesn't deploy; installing on devices is done from Xcode (TestFlight is a later decision).

**Order of runs.** Each workflow runs one at a time per branch. On `main` a running workflow is
never cancelled: the next one waits. GitHub keeps at most one waiting run per group (a newer
one replaces it), so when several merges land together the in-between ones are skipped and the
newest commit always deploys last. Deploys share one group across the repo, so they never
overlap. On pull requests, pushing a new commit cancels the older run.

Repo setting this relies on: **Settings → Pages → Source = GitHub Actions**.

Live site: https://zsolt-kali.github.io/vijf/

## Decisions

Newest last. When a decision changes, add a new entry instead of rewriting the old one.

### 1. One HTML file, no build step, no runtime dependencies
The whole app is `index.html` with inline CSS and plain JavaScript. It can be edited anywhere,
including on github.com from a phone, and nothing has to be compiled or kept up to date.
*Trade-off:* code can't be split into modules, which also rules out unit tests (see 9).

### 2. Data stays on the device
Progress is saved in `localStorage`, with no server or accounts. It's private and free, and it
works offline. *Trade-off:* no sync between devices; the back-up text is how data is moved.

### 3. Hosting on GitHub Pages
It's free for a public repo and includes HTTPS, which installable web apps and service workers
require. *Considered:* Cloudflare Pages and Netlify, which are equally good. GitHub was chosen to
keep the code and hosting in one place.

### 4. Deploy through GitHub Actions, not "Deploy from a branch"
Publishing from a workflow lets the deploy run tests first, stamp the cache version, and publish
only the app files (not tests, docs or `node_modules`).

### 5. Cache version stamped automatically with the commit ID
The service worker only updates phones when `sw.js` changes. A manual `CACHE` bump on every
release was easy to forget, and then phones stayed on the old version. The deploy now writes
`vijf-<commit>` into `sw.js`, and the repo copy stays `vijf-dev`.
*Rejected:* a git pre-commit hook (doesn't run for edits on github.com), and relying on
reminders in `CLAUDE.md` (not a guarantee).

### 6. Service worker: network-first for pages, cache-first for everything else
Pages come from the network when online, so updates appear on the next open, and fall back to
the cache offline. Icons and the manifest rarely change, so they're served from the cache.
*Trade-off:* on a very slow connection the first screen waits for the network.

### 7. Never change the storage key; migrate instead
Changing the saved data's key or shape would lose everyone's progress and break old back-ups.
Loaded data and restored back-ups both pass through `migrate()`, which upgrades old shapes.
The migration tests protect this.

### 8. "Decks" (stapels), not "boxes", for topic groups
"Box" already means one of the five Leitner boxes, so topic groups got a different name.

### 9. Deleting a deck: swipe, then undo instead of a confirm dialog
Swipe-to-delete is familiar from phone apps. A 5-second undo protects against mistakes without
asking "are you sure?" every time.

### 10. End-to-end tests with Playwright
Tests open the real app in a browser and use it like a person. That fits decision 1: there's no
separate logic layer to unit-test. Tests run in **Chromium as a Pixel 7** and **WebKit as an
iPhone 15**, the two engines people install the app with. There's one test file per
`SPEC.md` section, so a spec change points to the test that changes with it.
*Rejected:* unit tests (would need the app split into modules), and testing only in Chromium
(iPhone Safari is a main target and behaves differently).

### 11. Tests gate the deploy
Tests run on every push and pull request; `main` only deploys when they pass. A change that
breaks existing behaviour can't reach the live app.

### 12. Edit cards from the study screen; no all-cards list, no "delete everything"
Cards are fixed where they're met: a cog on the study card opens an edit form with delete.
The all-cards list was removed to keep the app small and focused on studying, and back-up
moved to its own button on the deck list. "Delete everything" was dropped as too risky for what
it offered. Restoring a back-up still replaces all data.
*Trade-off:* to fix a word you have to study its box until it comes up; there's no search.

### 13. English-only interface
The interface was Dutch with English subtitles, which doubled every label and made the screens
busy. It is now English only, short and plain; only the words being learned are Dutch. A single
language also keeps the upcoming iOS and watch apps simpler.

### 14. One design system for every app
The look is defined once, in the vijf design system on claude.ai (tokens, components and
guidelines, plus screen mockups for phone, web and watch), and copied into `design/tokens.json`.
The PWA's CSS variables mirror that file, a test fails if they drift, and the iOS and watch
apps will build from the same tokens. Dark mode follows the device. The system font stays,
because on Apple devices it is SF Pro, which keeps web and native identical.

### 15. Study sessions run in rounds
The first version of the position counter grew its total on every "Not yet" (3 / 12 → 4 / 13),
which read like the box had gained cards. Now a session runs in rounds: every answer moves the
position forward, the total of a round never changes, and the "Not yet" cards come back as the
next, shorter round with its own total (1 / 3).

### 16. One repo, a folder per app, a workflow per app
The web app moved to `web/` so the iOS and watch apps can live beside it in `apple/`, sharing
`SPEC.md`, `design/tokens.json` and the issue list. Each app has its own workflow, triggered only
by its own folder (or `design/`), so an iOS change never redeploys the web app and a web fix never
waits for a macOS build. Tests run once per pull request instead of once per push and once per
pull request, and every job has a time limit so a hung download fails in minutes.
*Considered:* a separate repo for the native apps; rejected because the spec, tokens and backup
format must stay in step across all three apps.

### 17. Native iPhone app: SwiftUI, a shared rules package, the backup JSON as storage
The iPhone app is SwiftUI (iOS 18+). Every rule lives in the `VijfKit` Swift package, which the
watch app will reuse and which is tested with plain `swift test`. The app saves the same JSON as
the web app's backup, so data moves between the two by copy and paste, and `Backup.decode`
mirrors the web app's `migrate()`. The Xcode project is hand-written with folder-synchronized
groups, so it stays small and needs no generator. Colours are generated from
`design/tokens.json`. Signing starts with a free Apple ID (installs expire after 7 days); the paid
developer program, for TestFlight, is a later decision.
*Considered:* SwiftData (a second storage format to keep in step with the backup JSON), and
XcodeGen or Tuist (another tool to install for one small project).

### 18. Apple Watch: study only, synced directly with the phone
The watch app only studies; managing cards stays on the phone. They sync over WatchConnectivity
with no server, so decision 2 (data stays on your devices) still holds. The phone sends its whole
library (small, and always the current state); the watch sends back only its "I know it" answers,
each with the card's new box. Because cards never move down, every merge is "keep the higher
box", which needs no conflict handling and is safe to repeat, so the watch can simply re-send
anything the phone might have missed.
*Considered:* iCloud/CloudKit sync (needs the paid developer program, and its timing is out of
our control), and syncing every answer including "Not yet" (they don't change the card).

### 19. Search all cards; New deck and Backup in a "⋯" menu
Fixing a word meant studying its box until it came up (decision 12). The deck list now has a
search field that finds cards in every deck and opens them in the existing edit form, so there
is still no all-cards list. To keep the deck list clean, New deck and Backup moved into a "⋯"
menu and the deck count was dropped from the header. Search stays on the page because it's used
often; the rarer actions take two taps. With no decks yet, the name field stays on the page so a
new user has an obvious first step.
*Considered:* one "Tools" button for all three (search would cost two taps every time), and a
hamburger (☰), which usually means navigation and isn't an iOS pattern; "⋯" means "more actions
here" on both platforms. The watch stays study-only, without search.

### 20. Hearing a word: the device's own voice, on tap
The Dutch side of the card can read the word aloud. It uses the speech built into the browser
(`speechSynthesis`) and iOS (`AVSpeechSynthesizer`), so there are no audio files, no service and
no new dependency, and it works offline where the device has a Dutch voice. It plays only when
tapped, never on flip, so studying in public stays quiet.
*Considered:* recorded audio or an online text-to-speech service (files to manage, or a network
and a server, against decision 2), and reading the word automatically on flip.
