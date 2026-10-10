# BoxRow

One of a deck's five Leitner boxes; tapping it starts a study round.

- Number block left (`ink` fill), name (`label`), up to 20 `deep` ticks (one per card), count right (`count`).
- Empty box: `line` border and number block, `mute` text.
- Box 5 with cards: the number block turns `signal` yellow.
- Names: New, Shaky, Getting there, Nearly, Learned.

The consumer provides the box number, name and card count.
