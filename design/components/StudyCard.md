# StudyCard

The flashcard: your language on the front (`card`), Dutch on the back (`signal` yellow); tap anywhere to flip.

- Hint top-left (`eyebrow`, uppercase), the word in the middle (`word`), the instruction bottom-left.
- **The cog sits inside the card, top-right**, on both faces, `space-gap` from the corner in a `tap-min` square. Tapping it opens the edit form and does **not** flip the card.
- On the back every mark is `on-signal`, the focus ring too.
- **Example sentence:** on a side that has one, a speech bubble sits left of the cog (`tap-min` square, same colours). Tapping it shows the sentence under the word in `body` (15px), `mute` on the front and `on-signal` on the back, with the card's word underlined (2px, `deep` / `on-signal`), and fills the bubble. It stays shown through a flip; the next card starts hidden. The bubble never flips the card.
- When browsing, both footers end with the card's box on the right ("Box 3"), and the back's footer reads "Tap to flip back".

The consumer provides both words and handles the flip (a 0.5s Y-rotation; instant with reduced motion). Words wrap and never truncate.

Watch: the card fills the screen without a border, and has no cog and no example sentence.
