# SearchField

The deck list's search box: one square input across the column, under the header, above the decks.

- No label above it: the placeholder "Search all cards" (in `mute`) says what it does. No magnifying-glass icon.
- `card` fill, 1.5px `ink` outline, 17px text so iOS does not zoom on focus; focus shows the `border-focus` ring in `deep`, like Field.
- While it has text, a **×** clear button sits inside it on the right, in `mute`, in a `tap-min` square.
- The keyboard's return key reads "Search" and only closes the keyboard; results update as you type.

The consumer provides the text binding and shows the results below (see DeckRow → Search result).
