# Shamba Ledger — download

- `README.md` — the brand book (voice, colour, type, layout, iconography, Flutter mapping).
- `tokens.json` — every token with its light and dark value and a usage note (source of truth).
- `tokens.css` — the same tokens as CSS custom properties; light by default, dark via `prefers-color-scheme` or `data-theme="dark"`.
- `components/bundle.css` — styles for every `sl-*` component (needs `tokens.css` loaded first).
- `components/<Name>/README.md` — guidelines; `preview.html` — the reference markup.
- `components.html` — open in a browser to see all components rendered, with a theme switch.
- `assets/Logos/` — logo notes. The logo files themselves (shamba-mark.svg, shamba-app-icon.png) download from the design system page.
