# Design

`tokens.json` is a copy of the vijf design system's tokens: colours for light and dark, type styles, spacing, borders and sizes. Every app builds from these values:

- **Web:** the `:root` and dark-mode blocks at the top of `index.html`.
- **iOS / watchOS (planned):** asset-catalog colours with Any and Dark appearances, named like the tokens.

The full design system, with the component guidelines, and the screen mockups live in claude.ai:

- Design system: https://claude.ai/artifact/Cyvk79v8nRck8cenN92cmR
- Screen mockups: https://claude.ai/artifact/QD59BPykasBaNm8hYv8cqU

When a token changes there, update this copy and the CSS in the same change.
