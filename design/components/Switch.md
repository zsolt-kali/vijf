# Switch

A setting that is either on or off, with the switch on the right of its row. Used for the three settings: **Classic Leitner**, **Search** and **Days in a row**; rows stack `space-gap` apart.

- The row: `card` fill, 1.5px `ink` outline, `space-pad` × `space-gutter` padding. Left: the name (`label`) and, under it, a `caption`-style mono line in `mute` that says what the current position does ("Missed cards go down one box" / "Missed cards go back to box 1"). Right: the switch.
- The switch: 56 × 32, square, 1.5px `ink` outline. **Off:** `paper` track, `ink` knob on the left. **On:** `ink` track, `on-ink` knob on the right. The knob is 23 × 23, 3px from the edges, and slides in 0.15s (instant with reduced motion). No red, green or yellow: those mean the answers and "learned".
- Tapping anywhere on the row flips it. It is a real switch for assistive tech (`role="switch"` with `aria-checked` on the web, a `Toggle` on iOS), named by the row's label.
- No help text under the row: the mono line says it.

The consumer provides the label, the two mono lines and the state. Web: `.setting` and `.switch` in `index.html`; iOS: `VJSwitchStyle`.
