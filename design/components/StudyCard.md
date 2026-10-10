# StudyCard

The flashcard: your language on the front (`card`), Dutch on the back (`signal` yellow); tap anywhere to flip.

- Hint top-left (`eyebrow`, uppercase), the word in the middle (`word`), the instruction bottom-left.
- **The cog sits inside the card, top-right**, on both faces, `space-gap` from the corner in a `tap-min` square. Tapping it opens the edit form and does **not** flip the card.
- **The speaker sits on the back only, just left of the cog**, in its own `tap-min` square, in `on-signal`. Tapping it reads the Dutch word aloud and does **not** flip the card. Leave it out where the device can't speak.
- On the back every mark is `on-signal`, the focus ring too.
- Box 5 cards say "Learned. Stays in box 5" on the back.

The consumer provides both words and handles the flip (a 0.5s Y-rotation; instant with reduced motion). Words wrap and never truncate.

Watch: the card fills the screen without a border, and has no cog or speaker.
