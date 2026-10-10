# Toast

A short confirmation at the bottom of the screen, centred, above the safe area.

- Plain toasts last 1.8 s: "Saved", "Deck created", "Box 3 is empty".
- Undo toasts last 5 s and carry an **Undo** action in `on-ink-accent`: after deleting a deck or a card. Only one undo is pending at a time.
- `ink` fill and `on-ink` text, so it inverts in dark mode.

The consumer provides the message (past tense, no full stop) and the undo callback.
