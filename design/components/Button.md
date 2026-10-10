# Button

A square, outlined action that fills its row; variants set the meaning.

- **Default** (`vj-btn`): `ink` outline, for secondary actions like Cancel and Backup.
- **Fill** (`vj-btn--fill`): `ink` fill. One per screen, for the main action: Save, Add words, Next.
- **Not yet / I know it** (`vj-btn--no`, `vj-btn--yes`): the two answers on the study screen, `danger` and `success` fills. Always side by side in that order, always with their words.
- **Danger** (`vj-btn--danger`): `danger` outline and text, for Delete card.
- **Ghost** (`vj-btn--ghost`): `line` outline and `mute` text, for optional extras like the starter set.

The consumer provides the label and, only when it adds information, a `<small>` subtitle ("stays in box 1"). Put buttons in a `vj-row`; they share the width equally.

Don't: add icons to buttons, use `success` or `danger` fills for anything but the two answers, or put two fills in one row unless they are the two answers.
