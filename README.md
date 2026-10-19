# vijf — Dutch flashcards

A five-box Leitner system for learning Dutch words, on the web, iPhone and Apple Watch.
New cards start in box 1. **I know it** moves a card up one box, **Not yet** moves it down one,
and each box comes up less often than the one before.

Live web app: **https://zsolt-kali.github.io/vijf/**

## How vijf works

<!-- The plain explanation for people using the app. Keep it in step with SPEC.md: update it in
     the same change whenever something a user would notice changes. -->

### Decks and boxes

Make a deck for each topic (food, work, …). Every deck has five boxes, and each box comes up
less often than the one before:

| Box | Name | Comes up |
|---|---|---|
| 1 | New | every day |
| 2 | Shaky | every 2 days |
| 3 | Getting there | every 4 days |
| 4 | Nearly | every 8 days |
| 5 | Learned | every 16 days |

New words always start in box 1.

### Studying

Open a deck, tap a box, and go through its cards that are due today, in random order. You see
your own language first; tap to flip to the Dutch. Then answer:

- **I know it:** the card moves up one box and waits that box's gap. From box 2 to box 3 means
  you see it again in 4 days. In box 5 it stays in box 5 and comes back in 16 days.
- **Not yet:** the card moves down one box (or back to box 1, with **Classic Leitner** on in **Settings**)
  and comes back tomorrow. In box 1 it can't go lower:
  it stays there, and at the end of the round you choose: **Go again** to practise the cards you
  missed straight away, or **Stop for today** to see them tomorrow.

Gaps count calendar days: a box 2 card answered on Monday evening is due on Wednesday morning.

A word's usual path: box 1, practised until you know it, then box 2 (2 days), box 3 (4 days),
box 4 (8 days) and box 5, checked every 16 days. Each **Not yet** moves it back one box and
brings it back the next day, so a word you forgot gets practised again soon.

### Settings

**Settings** in the ⋯ menu has three switches:
- **Classic Leitner:** off (the default), a card you answer **Not yet** goes down one box; on,
  it goes back to box 1, which is stricter. The iPhone's setting also applies on the Watch.
- **Search** and **Days in a row** (both on): switch them off to hide the search field or the
  streak from the deck list. Your finished days are still counted while the streak is hidden.

The line under each switch says what it does right now.

### Days in a row

A day counts as done when nothing is due in any deck. The deck list shows how many **days in a
row** you've done, with a square for each day this week, and what's next ("Finish today to make
it 13"). **One missed day a week is let off**; a second one starts you again. When you finish
the last card of the day, **Done for today.** shows your streak, what you did today and how many
cards come tomorrow. Answers on the Watch count too.

### Browsing a deck

Inside a deck, **Browse cards** shows all its cards one at a time, box 1 first, without
answering: nothing moves between boxes. A dark band at the top says **Browsing**. Use
**← Previous** and **Next →** (or the arrow keys in the web app); on the last card, **Done**
takes you back. It works on the Watch too.

### What the screens tell you

- **Deck list:** each deck shows what's left for today ("8 left today", or "Done for today")
  and, on the right, how many cards are learned out of the total (7/12).
- **Inside a deck:** each box shows its card count. If only some of its cards are due, it says
  "3 left today". If none are, it's greyed out and says when the next one comes up ("Next
  tomorrow", "Next in 4 days").
- **Between box 1 rounds:** "Round 1 done. 11 not yet." with **Go again** and **Stop for today**.
- **After a session:** a summary such as "Moved up to box 4: 3. Back to box 2: 1."
- **The cog** on a card lets you fix a typo or delete the card. **Search all cards** on the deck
  list finds a word in any deck.

### iPhone and Apple Watch

The Watch is for studying only. It keeps its own copy of your decks, so it works without the
phone nearby, and sends every answer to the phone. If you answer the same card on both before
they sync, the most recent answer wins.

### Which version do I have?

The **Backup** screen (⋯ menu) ends with a line like "Version 3116643 · 15 Oct 2026": the code
the app was built from and its date. On the Watch it's at the bottom of the deck list. The iPhone
and the Watch always show the same version. The web app can show an older one, because it only
updates when something in the web app itself changes.

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

- Progress does not sync between devices (except iPhone and Apple Watch). Each one has its own
  boxes.
- Clearing browsing data for the site erases it. Use **Backup** on the deck list to copy
  your cards out, and paste that text into the same screen on another device to restore.

## Making changes

See [DEVELOPMENT.md](DEVELOPMENT.md) for the workflow, the tests and how deploying works.
In short: open an issue, work on a branch, open a pull request, and merge it. The web app
deploys automatically once the tests pass, and phones get the new version the next time
they open the app.
