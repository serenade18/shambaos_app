# PhoneField

PhoneField takes a phone number or sign-in code: one large field, mono digits, with the country code fixed in a prefix.

## Anatomy

- `label` above the field, always visible (no placeholder-only labels).
- A `tap-primary` (56px) box, `sheet` with a 1.5px `rule-strong` border and `radius-m`. Focus draws the 3px `focus` ring.
- The prefix ("KE +254") in a `sheet-sunk` well, tappable to change country.
- Digits in `code` (Atkinson Hyperlegible Mono, 19px, slightly tracked), grouped as people write them: `712 345 678`.
- A hint line in `caption`. In the error state (`sl-field--error`) the border and hint turn `danger-ink` and the hint says what to do.

## Provide

The value, the country, a hint, and an error message from the API's `message`. Accept a number typed with a leading 0 or with +254, and normalise it before sending.

## Do and don't

- Do open the phone keypad (`inputmode="tel"`, or `numeric` for codes) and support SMS autofill for codes.
- Do keep the typed number when showing an error.
- Don't split a sign-in code into six separate boxes that fight paste and autofill.
