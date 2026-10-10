# vijf brand book

vijf is a five-box Leitner flashcard app for learning Dutch words. It runs as a web app (PWA) and, built from this system, as iOS and watchOS apps. Every surface uses the same tokens, so the three look and read the same.

## Content

- **English only, short and plain.** Only the words being learned are Dutch. Sentence case everywhere ("Add words", "Round complete.").
- **Buttons say what happens:** `Create`, `Save`, `Delete card`, `I know it`, `Not yet`, `Next`. Toasts confirm in past tense: "Deck deleted", "Saved", "Restored".
- **A subtitle line only when it adds information:** `Not yet` / "stays in box 1", `I know it` / "→ box 2". Never a translation of the label.
- **Numbers are figures:** "3 / 12", "Box 3 is empty", "12 words added to box 1".
- No emoji, no exclamation marks, no apologies.

## Colour

- `paper` is the page, `card` the raised surface, `ink` the text and every 1.5px outline. Primary buttons are an `ink` fill with `on-ink` text.
- `signal` yellow means **learned**: the back of the study card and the number of a filled box 5. Text on it is always `on-signal`, in both themes.
- `deep` blue is for **progress and focus**: the tick marks in a box row, the wordmark's dot, the focus ring, and the underline that marks a search match (not yellow, which would read as "learned").
- `success` and `danger` are reserved for the two answers: **I know it** is a `success` fill and **Not yet** a `danger` fill, with `on-success` / `on-danger` text. `danger` is also the swipe-to-delete fill and the outline of **Delete card**. Never use them for decoration.
- Red and green are close in lightness, so they never carry meaning alone: each button keeps its words, and the two keep their fixed order (Not yet left, I know it right).
- Empty or inactive elements use `line` borders and `mute` text.
- **Dark mode follows the device.** Every colour has a dark value; no component sets a literal colour.

## Type

- One family per role: `sans` (the system face: SF Pro on Apple devices, so web and iOS match) and `mono` for labels, counts and the top bar.
- Display styles are heavy and tight: `wordmark`, `word` (the card), `heading`. Text styles: `label` for row names, `button`, `body`, `note`.
- Mono styles are small and uppercase with letter-spacing: `tally` (top bar), `eyebrow` (field labels, card hints), `caption` (button subtitles), `count` (row counts, tabular figures).

## Shape and layout

- **Square.** `radius-none` everywhere: cards, rows, buttons, inputs, toasts. No shadows. Objects are set apart by a `border-stroke` outline, not by elevation.
- One column, `content-max` wide, with a `space-gutter` side gutter. Stacked rows and button rows are `space-gap` apart; the study card has `space-section` padding.
- Tap targets are at least `tap-min`.
- Focus: a `border-focus` ring in `deep`, offset 2px. On a `signal` surface the ring is `on-signal`.

## Motion

- The study card flips in 0.5s (`cubic-bezier(0.2, 0.7, 0.2, 1)`); a swiped deck row narrows in 0.2s. With reduced motion, both are instant.

## Iconography

- **The mark:** five bars narrowing downward, one per Leitner box, with the top bar (box 5,
  learned) in `signal` yellow on an `ink` square. It is the app icon and, drawn as shapes, the
  watch-face complication.
- One interface icon: the **cog** (Feather "settings", MIT), stroke 2, `icon-size`, in `mute` (on the yellow back, `on-signal`). It sits inside the study card, top-right, `space-gap` from the corner, in a `tap-min` square.
- A second interface icon, the **speaker** (Feather "volume-2", MIT), with the same stroke, size and colour rules as the cog. It sits on the back of the study card only, just left of the cog, in its own `tap-min` square.
- No other icons and no emoji. Arrows in text use the "→" and "←" characters; the deck list's menu button is the "⋯" character and the search field's clear button "×", both in text, not icons. No magnifying glass: the placeholder "Search all cards" says what the field does.

## Platforms

The tokens' source of truth in the code is `design/tokens.json` in the vijf repo; tests fail if the
web CSS or the Swift colours drift from it.

- **Web:** the CSS custom properties at the top of `web/index.html` hold the tokens, light and
  dark (`prefers-color-scheme`); `<meta name="theme-color">` is set for both schemes. This design
  system's `tokens.css` and `vj-` classes in `components/bundle.css` are the reference the
  mockups use.
- **iOS:** colours come from `VijfKit.Tokens` (generated from `design/tokens.json` by
  `apple/scripts/generate_tokens.py`) as dynamic colours that switch with the device appearance
  (`VJ` in `Theme.swift`). `sans` is `Font.system`, `mono` is `Font.system(design: .monospaced)`.
  Square corners and 1.5pt outlines. Platform conventions where they help: the system back button
  and title instead of the breadcrumb (the counter sits top-right), the system swipe action to
  delete a deck in `danger`, add words as a sheet, and the SF Symbols "gearshape" as the cog and "speaker.wave.2" as the speaker.
  The "⋯" button opens the system menu (rounded, as iOS draws it) and New deck is a system
  prompt with a name field; the button itself stays square.
- **watchOS:** study only, always dark (each token's dark value). No search or menu. Deck list → the deck's boxes →
  study. The card fills the screen without a border, tap flips it, and **Not yet** / **I know it**
  sit side by side below it as 44pt `danger` / `success` fills. The position counter ("3 / 12")
  sits in the top bar. No cog: editing happens on the phone. No speaker either.
- **Watch complication:** the mark, drawn as shapes. On tinted faces the top bar takes the face's
  accent colour and the other bars stay white; on full-colour faces the top bar is `signal` yellow
  and the rest light, as in the icon. Inline complications show the word "vijf".
