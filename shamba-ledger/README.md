The farm record book, legible in the noon sun.

Shamba Ledger is the design system for ShambaOS, the farm app used by smallholder farmers in Kenya to keep records of their animals, crops, stock and money. The people using it are outdoors, on budget Android phones, often in bright sun, sometimes with dirty or gloved hands, and many of them have kept their records for years in a ruled counter book. Design for that person, not for a desk.

Three ideas run through every screen:

1. **A ledger, not a dashboard.** Records sit in ruled rows with the figure on the right, the way a counter book is kept. Totals take a double rule. Quantities are in the units a farmer counts in: trays, bags, debe, litres, birds.
2. **Built for sunlight and thumbs.** Body text is larger than usual, contrast is high in both themes, and anything tappable is at least `tap-min` (48px). The actions people take in the field are `tap-primary` (56px).
3. **Seasons are the calendar.** Kenyan farming runs on the long rains (masika, March to May) and the short rains (vuli, October to December). Time is shown against those seasons, not against quarters.

## Content fundamentals

**Voice.** Write like an experienced extension officer talking to a farmer they respect: plain, warm, direct, and specific. Use "you" for the farmer. Never "we" for the app.

- Say what happened and what to do. "That code is not correct. 3 tries left." Not "Invalid OTP."
- Name things the way farmers do. "Your layers", "Maize field", "Feed store". Do not show system words such as *enterprise*, *module*, *item* or *sync conflict*.
- Sentence case everywhere, including buttons ("Record today's eggs"). Capitals only in `eyebrow` stamps, written in capitals in the copy: "VULI · SHORT RAINS".
- No emoji in the interface. The catalogue's emoji are data, not icons.
- Buttons state the action and its object: "Save sale", "Send code", "Add customer". The confirmation repeats it: "Sale saved".

**Languages.** Every string ships in Swahili and English (French follows the same rules). Swahili runs about a quarter longer, so give labels room to wrap to two lines rather than truncating, and never put text in a fixed-width chip.

**Numbers and money.**

- Money is `KSh 22,500`: the KSh prefix, a comma for thousands, no decimals for whole shillings. Show cents only on prices per unit (`KSh 12.50 / egg`).
- A loss is written with a minus sign and a word, never colour alone: "−KSh 1,200 loss" in `danger-ink`.
- Quantities always carry their unit word, in the unit the farmer uses: "212 trays", "3 bags", "18 litres". Never base units (pieces, kg of eggs). A bag of maize is 90 kg; a bag of feed is 50 or 70 kg, so name the bag size where it matters ("3 bags (70 kg)").
- Phone numbers are shown as farmers write them: `0712 345 678`. The +254 lives in the field prefix.
- Dates: "Thu 15 Oct", or relative within a week ("today", "yesterday", "3 days ago"). Seasons by name: "Short rains 2026".

**Real copy, for reference.**

> Mama Njeri has owed you KSh 18,000 for 12 days.
> Heavy rain expected Thursday, about 34 mm.
> Newcastle vaccine due for Layers, batch 1 by Fri 23 Oct.
> Layers mash is running low: 3 bags left.

## Visual foundations

**Colour.** Three layers of neutral make all the depth: `paper` is the page, `sheet` holds records, `sheet-sunk` is an inset well inside a sheet. Separate them with `rule`, not shadows. The neutrals lean toward the logo's green on purpose: no pure grey, no pure white.

- `shamba` is the logo green and the only strong fill: primary buttons, the profit band, the active tally. Text on it is always `on-shamba`. In dark mode `shamba` turns light and `on-shamba` turns dark, so never hard-code white on green.
- `shamba-ink` is green as text: links, quiet buttons, the active nav label, good deltas.
- `maize` means **here and now** and nothing else: today's marker on the season strip and the active tab. It is never text (use `maize-ink`), never a large fill, and never used for warnings.
- Status uses its own colours, separate from the brand: `good-*` (which aliases the brand green), `warn-*`, `danger-*`, and `rain-*` for weather and information. Each comes as an `-ink` for text and icons and a `-tint` for the background of a tag or icon well. Every status also carries a word and an icon, because good and danger are not told apart by hue alone.
- Text pairs hold 4.5:1 or better in both themes: `ink` and `ink-muted` on `paper`, `sheet` and `sheet-sunk`; `ink-faint` on `paper` and `sheet` only.

**Type.** Two families do the work, plus a mono for codes.

- `display` (Zilla Slab) is for figures and titles: `figure-xl`, `figure-l`, `figure-s`, `title-l`, `title-m`. Its sturdy slab numerals read like the stamped print on a feed sack. Use it for numbers and names of things, never for sentences.
- `text` (Atkinson Hyperlegible Next) is for everything people read: `body-l` for sentences, `body` for dense rows, `label` for row titles and buttons, `caption` for units and metadata, `eyebrow` for season stamps. It was drawn for low-vision readers, so 0 and O, 1 and l, and 5 and S never get confused.
- `mono` (Atkinson Hyperlegible Mono) is for what people type or copy character by character: `code` for the phone number and sign-in code being entered, `code-s` for M-Pesa codes and animal tags inside rows.
- Give every column of digits `font-variant-numeric: tabular-nums` so figures line up down a ledger.
- One `figure-xl` per screen. If two numbers compete, one of them is a `figure-l`.

**Layout.** One column, a `space-4` (16px) gutter, sections `space-6` apart. Put the summary before the detail: the key figure, then the ledger that explains it. Group rows into a ledger (one `sheet` with `rule` between rows) rather than a stack of separate cards. End every scrolling screen with `space-12` so the last row clears the thumb and the nav.

**Shape.** `radius-m` (10px) for sheets, ledgers, buttons and fields; `radius-s` (6px) for inset wells; `radius-l` (20px) only for the top of a bottom sheet; `radius-pill` only for status tags and choice chips. Buttons are never pills.

**Borders and shadows.** A sheet has a 1px `rule` border and no shadow. Controls use a 1.5px `rule-strong` border. A ledger total sits under a 3px double `rule-strong` rule, the bookkeeper's mark for a sum. The only shadow is `shadow-sheet`, on bottom sheets and dialogs.

**States.** Pressed: darken the fill by laying `ink` over it at 8%. Disabled: 45% opacity and no pointer. Focus: a solid 3px `focus` ring, offset 2px, on every interactive element; it holds 3:1 on paper and sheet in both themes. Loading: a `sheet-sunk` block the shape of what is coming, never a spinner over content that is already there.

**Motion.** Short and plain: 160 to 220ms, ease-out, no bounce, no count-up animations on figures. Sheets slide up; screens cross-fade. Respect the reduced-motion setting by removing movement, not just shortening it.

**Imagery.** Real photographs of Kenyan farms and farmers, unfiltered. When text sits on a photo, lay `ink` at 55% over the bottom half; never a coloured gradient. No stock illustrations of smiling cartoon farmers.

## Iconography

- Line icons, 24px on a 24px grid, 2px stroke, round caps and joins, drawn in `currentColor`. That matches the logo, a leaf drawn as one round-capped stroke.
- Use **Phosphor Icons (Regular weight)**; in Flutter, the `phosphor_flutter` package. Do not mix in Material's filled icons.
- Animals and crops get their own drawn icons in the same stroke (cow, goat, sheep, pig, rabbit, hen, fish, maize, beans, tomato, kale, banana, avocado). The app's current coloured PNG illustrations do not follow this and should be redrawn; until then, show them inside a `shamba-tint` well at 28px.
- An icon in a status tag or alert always sits next to a word. Icon-only buttons need an accessible label and a `tap-min` target.

## Logo

The mark is a white leaf on a `shamba` disc (`assets/Logos/shamba-mark.svg`). Keep clear space of a quarter of its diameter on every side. Show it at 32px or larger. On `shamba` fills use the bare white leaf; never recolour the disc, add a gradient or put it on a photo without a `sheet` behind it.

## Building it in the app

The Flutter app already has an `AppColors` theme extension with a light and a dark set. Map these tokens onto it, one-to-one, and use `context.appColors.<token>` in every widget; never a raw `Color(0xFF…)` for a neutral or a brand colour.

| Token | `AppColors` field |
| --- | --- |
| `paper` | `scaffoldBackground` |
| `sheet` | `cardBackground`, `chipBackground` |
| `sheet-sunk` | `surfaceMuted` |
| `rule` / `rule-strong` | `divider` / `border` |
| `ink` / `ink-muted` / `ink-faint` | `textPrimary` / `textSecondary` / `textHint` |
| `shamba` / `shamba-ink` / `shamba-tint` | `AppColors.brand` (make it themed) / `brandText` / `brandSoft` |

Add the fields the app does not have yet (`on-shamba`, `maize`, `maize-ink`, `season-rain`, and the four status pairs) to the same extension. Bundle the three font families as assets (or use the `google_fonts` package) and build a `TextTheme` from the type styles above.
