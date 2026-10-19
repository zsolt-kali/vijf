# Streak

Days in a row: a line on the deck list and a card on the Done for today screen. `deep` blue, the colour of progress, is the only colour; yellow stays "learned".

- **Deck list line**, under the header: "12 DAYS IN A ROW" in `tally`-style mono (the number bold, `deep` once today is done), and under it a `caption`-style line in `mute` saying what's next ("Finish today to make it 13", "Done for today · Tomorrow 18 cards"). On the right, the week.
- **The week:** seven squares, Monday to Sunday, 12 × 12 on the deck list (16 high and full width on the Done card), 3–4px apart, square. `deep` fill = done; 1.5px `ink` outline = today, not done yet; 1.5px `line` outline = missed or still to come.
- **Done card:** `card` fill, 1.5px `ink` outline. The count large (40px mono, `deep`) with "DAYS IN A ROW" beside it, the week full width, and the weekday names under it in `caption` mono.
- No flames, badges or exclamation marks: the numbers are the reward.

Web: `.streak`, `.week` and `.done-card` in `index.html`; iOS: `StreakLine`, `WeekSquares` and `DoneTodayView`.
