# BoxRow

One of a deck's five Leitner boxes; tapping it starts a study round.

- Number block left (`ink` fill), name (`label`), up to 20 `deep` ticks (one per card), count right (`count`).
- Empty box: `line` border and number block, `mute` text.
- Some cards answered today: a `caption`-style mono line in `mute` under the name, "8 left today". None left: "Done for today", and the row looks like an empty box (no ticks) but keeps its count. Box 5 never shows it.
- Box 5 with cards: the number block turns `signal` yellow.
- Names: New, Shaky, Getting there, Nearly, Learned.

The consumer provides the box number, name, card count and the number due today.
