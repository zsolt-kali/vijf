# DeckRow

A deck on the deck list: name, card count, and learned out of total; swipe left to delete.

- Swiping left narrows the row by `swipe-reveal` and shows a `danger` **Delete** area on the right (second row). Deleting shows a 5-second undo toast.
- An empty deck uses `line` and `mute`, like an empty box.
- The name never moves off-screen while swiping: the row narrows, it does not slide.

The consumer provides the name and the counts, and handles the gesture (iOS: the system swipe action in `danger`).
