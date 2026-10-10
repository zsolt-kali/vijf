# Menu

The **⋯** button on the right of the deck list's header, and the short list of actions it opens: **New deck**, **Backup**.

- The button is a `tap-min` square with a 1.5px `ink` outline and the "⋯" character in `ink`; while the menu is open it inverts to an `ink` fill with `on-ink`.
- Web: the menu drops down under the button, right-aligned: a `card` panel with an `ink` outline, one `label`-weight row per action divided by `line`. The rest of the screen fades back while it is open; any tap outside it, or Escape, closes it without doing anything else.
- iOS: the system menu, as iOS draws it. New deck is a system prompt with a name field (Cancel / Create).
- Actions only (verbs or screen names), never navigation between sections: that would be a hamburger, which vijf doesn't use.

The consumer provides the actions.
