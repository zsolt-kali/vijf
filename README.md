# vijf — Dutch flashcards (installable web app)

A five-box Leitner system. New cards start in box 1. **Ken ik** moves a card up one box,
**Nog niet** leaves it where it is. Box 5 is the end of the line — cards stay there.

## Files

```
index.html              the whole app
manifest.webmanifest    name, colours, icons for installing
sw.js                   offline support
icons/                  home screen icons
```

## Hosting it free with GitHub Pages

You can do all of this from a phone browser.

1. Make a free account at github.com.
2. Create a new **public** repository called `vijf`.
3. Choose **uploading an existing file**, and upload `index.html`,
   `manifest.webmanifest`, `sw.js`, and the whole `icons` folder.
   Keep `icons` as a folder — the paths matter.
4. Go to **Settings → Pages**. Under *Build and deployment*, set Source to
   **GitHub Actions**. The workflow in `.github/workflows/deploy.yml` publishes the site
   on every push to `main`.
5. Wait a minute or two. Your app is live at
   `https://YOUR-USERNAME.github.io/vijf/`

Free forever for a public repo, with HTTPS included — which a home screen app requires.

Alternatives that are equally free: **Cloudflare Pages** and **Netlify** (drag the folder
onto netlify.com/drop from a computer, no account needed to start).

## Installing it on your phone

**iPhone (Safari — it must be Safari):** open the link, tap the Share button,
scroll to **Add to Home Screen**.

**Android (Chrome):** open the link, tap the ⋮ menu, tap **Install app** or
**Add to Home Screen**.

You'll get the icon on your home screen and the app opens without browser chrome.
It works offline after the first load.

## Where progress is stored

In your browser's local storage on that device — private, no account, no server.
Two things to know:

- Progress does not sync between phone and laptop. Each device has its own boxes.
- Clearing browsing data for the site erases it. Use **Alles → Back-up maken** to copy
  your cards out, and paste that text into the same screen on another device to restore.

## Making changes later

Edit `index.html` in GitHub and commit. The workflow in `.github/workflows/deploy.yml`
publishes the site and stamps a new cache version automatically, so there's nothing to bump.
Phones that are online get the new version the next time they open the app.

This needs **Settings → Pages → Source** set to **GitHub Actions** (not "Deploy from a branch").
