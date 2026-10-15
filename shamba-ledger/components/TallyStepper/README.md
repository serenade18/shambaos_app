# TallyStepper

TallyStepper is how a farmer enters a count outdoors: big minus and plus buttons around the number, with shortcuts in the units they really count in.

## Anatomy

- A label row: what is being counted (`label`) and for which enterprise and day (`caption`).
- Two `tap-primary` (56px) buttons with `radius-s`. Minus is a `sheet-sunk` well; plus is the `shamba` fill, because adding is the common action.
- The number in `figure-l` with its unit underneath. Tapping the number opens the numeric keyboard for typing a large count.
- Shortcut chips for packs ("+10 trays", "+1 crate" = 12 trays) and a unit switch (Trays / Eggs). A tray is 30 eggs; a crate is 12 trays.

## Provide

The starting value, step sizes from the item's units, the unit labels, and the limits (never below zero; warn above the flock's possible output).

## Do and don't

- Do announce the new value to screen readers (`aria-live`).
- Do keep the last value if the person leaves and returns.
- Don't use a slider for counts.
