# DeckRow

A deck on the deck list: name, card count, and learned out of total; swipe left to delete.

- Swiping left narrows the row by `swipe-reveal` and shows a `danger` **Delete** area on the right (second row). Deleting shows a 5-second undo toast.
- An empty deck uses `line` and `mute`, like an empty box.
- The name never moves off-screen while swiping: the row narrows, it does not slide.

The consumer provides the name and the counts, and handles the gesture (iOS: the system swipe action in `danger`).

## Search result

The same row shape for a card found by search, which replaces the deck rows while there is a query.

- First line: the word in your language, in `label`. Second line: the Dutch word in `body` `ink`, then " · " and the deck name in `mute`.
- Right: the card's box number in `count` mono, on an `ink` fill with `on-ink` text, or `signal` with `on-signal` for box 5 (learned).
- The matching part of either side is underlined, 2px `deep`. Above the rows, an `eyebrow` count: "3 cards", "1 card", "No cards match".
- No swipe. Tapping opens the card's edit form.
