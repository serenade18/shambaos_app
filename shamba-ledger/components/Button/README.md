# Button

A button states one action and its object, in sentence case: "Send code", "Save sale", "Add customer".

## Variants

- **Primary** (`sl-btn--primary`): `shamba` fill with `on-shamba` text. One per screen, for the action the screen exists for. Use `sl-btn--lg` (56px, `tap-primary`) and full width (`sl-btn--block`) for actions taken outdoors: sending a sign-in code, saving a record.
- **Secondary** (`sl-btn--secondary`): `sheet` with a 1.5px `rule-strong` border. For the second choice beside a primary.
- **Quiet** (`sl-btn--quiet`): `shamba-ink` text, no fill. For "See all", "Edit", links inside a ledger head. Still at least `tap-min` (48px) tall.
- **Danger** (`sl-btn--danger`): `danger-ink` outline. For removing or reversing a record; confirm it in a bottom sheet that names what will be lost.

## Provide

The label, an optional leading icon (22px line icon, `currentColor`), and a disabled state while a request is running. When busy, keep the label and add a small spinner after it; do not swap the label for a spinner.

## Do and don't

- Do keep buttons `radius-m`. Never pill-shaped.
- Do write the result in the confirmation: "Sale saved".
- Don't put two primary buttons on one screen.
- Don't use maize for a button. Maize means "here and now", not "press me".
