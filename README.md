# vijf — Dutch flashcards

A five-box Leitner system for learning Dutch words. New cards start in box 1. **I know it**
moves a card up one box, **Not yet** keeps it there. Box 5 is the end of the line.

Live web app: **https://zsolt-kali.github.io/vijf/**

## What's in this repo

```
web/            the web app (PWA): index.html, service worker, icons, Playwright tests
apple/          the iOS and watchOS apps (Xcode project + shared VijfKit package)
design/         the design tokens every app is built from
SPEC.md         what the apps do
DEVELOPMENT.md  how to build, test and ship, and why it's set up this way
```

## Installing the web app on your phone

**iPhone (Safari; it must be Safari):** open the link, tap the Share button,
scroll to **Add to Home Screen**.

**Android (Chrome):** open the link, tap the ⋮ menu, tap **Install app** or
**Add to Home Screen**.

You'll get the icon on your home screen and the app opens without browser chrome.
It works offline after the first load.

## Where progress is stored

On your device only: private, no account, no server. Two things to know:

- Progress does not sync between devices. Each one has its own boxes.
- Clearing browsing data for the site erases it. Use **Backup** on the deck list to copy
  your cards out, and paste that text into the same screen on another device to restore.

## Making changes

See [DEVELOPMENT.md](DEVELOPMENT.md) for the workflow, the tests and how deploying works.
In short: open an issue, work on a branch, open a pull request, and merge it. The web app
deploys automatically once the tests pass, and phones get the new version the next time
they open the app.
