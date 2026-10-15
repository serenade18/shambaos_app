# KeyFigure

KeyFigure shows the one number a screen is about, large, with its unit and how it changed.

## Anatomy

- `eyebrow` label in capitals saying what and over which period: "PROFIT · LAST 30 DAYS".
- The value in `figure-xl` (Zilla Slab, 40px, tabular numerals). Money takes a small `KSh` prefix in `label` weight, top-aligned; quantities take their unit word after the number in `ink-muted`.
- A delta line in `body`: an arrow icon, the change in bold, and what it is compared with. More is `good-ink`, less is `danger-ink` (`sl-figure__delta--up` / `--down`), but the words always say which.

## Variants

- **Band** (`sl-figure--band`): on a `shamba` fill, all text `on-shamba`. Use once, for the headline money figure on Home or the dashboard.
- **Plain**: on `paper` or inside a `sheet`.

## Provide

The value already formatted (`22,500`), the unit or currency, the period label, and the comparison sentence. Format money as `KSh 22,500` with no decimals.

## Do and don't

- Do keep one `figure-xl` per screen. A second important number is a `figure-l` in a tile.
- Do show a loss as "−KSh 1,200" with the word "loss" in the delta.
- Don't animate the number counting up.
