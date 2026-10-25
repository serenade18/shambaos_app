# Shamba OS mobile app: design

How the app looks, reads and behaves, and why. It follows the **Shamba Ledger**
design system. The screens are drawn on the design canvas, "Shamba OS mobile
app screens" (https://claude.ai/artifact/Qae723GLs7RVGZPDGfUWSy). The canvas is
the reference: when the app and the canvas differ, the canvas wins, unless this
file says otherwise.

---

## 1. What the app is for

Shamba OS helps Kenyan smallholder farmers keep records of their animals and
crops, and see what those records add up to: profit, stock, alerts and weather
for their own land.

**Everything else serves one aim: recording must be simple.** A farmer standing
in a cow shed, with one hand free and patchy signal, should get a day's record
down in a few taps. Every screen is judged against that.

### Principles

1. **Tap, don't type.** Choices are chips, pickers and steppers. Free text only
   for names and notes.
2. **Start from what's likely.** Dates default to today. Names fill themselves
   in ("Dairy herd", "Sukuma, Oct 2026"). A day's record starts from yesterday's
   numbers. Tags number themselves on from the herd's last one.
3. **One screen, one job.** Each form records one thing, with one primary button
   fixed at the bottom.
4. **No dead ends.** Every empty state says what to do and links to it. Nothing
   says "coming soon".
5. **The farmer's words.** "Cow (female)" and "Bull (male)", not "sex: F".
   Acres, not hectares. Trays, not pieces. Swahili and French throughout.
6. **Show the money plainly.** Figures are big and set in tabular digits. Losses
   are in red, and never only in red.

---

## 2. Foundations

The tokens live in `lib/services/app_colors.dart` and `lib/services/app_type.dart`.
They mirror `shamba-ledger/tokens.json`. Read colours through
`context.appColors`, never as hex in a screen.

### Colour

| Token (app) | Ledger name | Light | Dark | Use |
|---|---|---|---|---|
| `scaffoldBackground` | paper | `#EEF1EA` | `#101511` | The page |
| `cardBackground` | sheet | `#FAFBF7` | `#182019` | Cards, ledgers, inputs, nav |
| `surfaceMuted` | sheet-sunk | `#E4E9DF` | `#222B23` | Wells inside a sheet |
| `textPrimary` | ink | `#17211A` | `#E8EDE5` | Text |
| `textSecondary` | ink-muted | `#4C574E` | `#A3AFA4` | Metadata, units |
| `textHint` | ink-faint | `#637065` | `#879386` | Placeholders, inactive nav |
| `divider` | rule | `#D3DACD` | `#2F3A31` | Hairlines between rows |
| `border` | rule-strong | `#7F8C7D` | `#6B786C` | Control borders |
| `shamba` | shamba | `#355442` | `#8FC9A0` | Primary buttons, selected states |
| `onShamba` | on-shamba | `#FFFFFF` | `#0F1A12` | Text on `shamba` |
| `brandText` | shamba-ink | `#2F5B40` | `#9ED4AE` | Green text, links, icons |
| `brandSoft` | shamba-tint | `#DCE8DD` | `#1F3427` | Icon wells, selected chips |
| `maize` | maize | `#D99A1E` | `#E8B04A` | *Here and now* only: today, the active tab |
| `goodInk` / `goodTint` | good | `#2F5B40` / `#DCE8DD` | `#9ED4AE` / `#1F3427` | Done, on track |
| `warnInk` / `warnTint` | warn | `#9A4A0B` / `#F6E3CF` | `#F2A66A` / `#3A2614` | Due soon, not mapped |
| `dangerInk` / `dangerTint` | danger | `#A3261B` / `#F7DEDA` | `#FF8A7A` / `#3D1C18` | Errors, losses, deaths |
| `rainInk` / `rainTint` | rain | `#1F5F82` / `#DCEBF2` | `#8CC4E3` / `#172A35` | Weather, information |
| `focus` | focus | `#1F5F82` | `#8CC4E3` | 3px focus ring |

Rules:
- Green means "the farm" and "go". Maize is kept for *today*, so it keeps its
  meaning.
- A status is always a word plus a colour (`SlTag('Done', tone: good)`), never
  colour alone.
- Dark mode is a full palette, not an inverted one. Test both.

### Type

Three families, bundled in `fonts/`:

- **Zilla Slab**: figures and titles.
- **Atkinson Hyperlegible Next**: everything people read. It was chosen for
  low-vision readers and bright sunlight.
- **Atkinson Hyperlegible Mono**: tags and codes, read character by character
  (`KE-013`, OTP codes).

| Style | Face | Size / line | Weight | Use |
|---|---|---|---|---|
| `figureXl` | Zilla Slab | 40/44 | 600 | The one key figure on a screen |
| `figureL` | Zilla Slab | 28/32 | 600 | Summary tiles, the tally stepper |
| `figureM` | Zilla Slab | 20/24 | 600 | Enterprise tiles |
| `figureS` | Zilla Slab | 17/22 | 600 | The right-hand figure of a ledger row |
| `titleL` | Zilla Slab | 24/30 | 600 | Screen titles |
| `titleM` | Zilla Slab | 19/24 | 600 | Section titles ("Today", "My fields") |
| `bodyL` | Atkinson | 17/26 | 400 | Lead text |
| `body` | Atkinson | 15/22 | 400 | Body |
| `label` | Atkinson | 15/20 | 700 | Field labels, row titles |
| `caption` | Atkinson | 13/18 | 400 | Metadata, hints |
| `eyebrow` | Atkinson | 12/16, +0.96 tracking | 700 | Capitals stamped above a title: "ADD AN ANIMAL" |
| `code` | Atkinson Mono | 19/24 | 500 | Tag inputs, OTP |

Figures always use tabular, lining digits. Write eyebrow copy in capitals
yourself; don't transform it in code.

### Space, shape, depth

- **Grid:** 4pt. Screen gutter 16. Gaps between sections 24. Between form
  fields 18. Inside cards 12–16.
- **Phone frame:** designed at 390 × 844, and must hold at 360 wide.
- **Radius:**
  - Cards and ledgers: 24
  - Fields: 14
  - Small wells: 10
  - Chips, buttons and tags: 999 (pills)
  - Bottom sheets: 28 on the top corners
- **Shadow:** one soft shadow for raised sheets: `0 8 24 rgba(23,33,26,.07)`.
  Nothing else is raised.
- **Touch targets:** 44 × 44 minimum. Primary buttons are 56 high. Tally
  steppers are 56 round.
- **Bottom nav:** a 72-high bar with a centre button that rises 28 above it.
  Scrolling pages pad their bottom by `AppBottomNav.scrollPadding(context)` so
  the last row is never hidden.

### Icons

- **Line icons** (Lucide, 24 grid, 2px stroke) via `LineIcon(path)`, for
  actions and rows.
- **Phosphor** (`PhosphorIconsRegular`) for system glyphs: back, x, caret,
  plus. Only the glyphs bundled in `lib/widgets/phosphor_icons.dart` exist.
- **Farm pictures** for animals and crops come from `images/assets/icons`
  (`fieldIcon(type)`): the cow, the hen, the maize cob. Use these pictures
  rather than an icon or a photo whenever something on the farm is shown.

---

## 3. Components

The design system's components and their Flutter widgets (`lib/widgets/`):

| Ledger | Widget | Notes |
|---|---|---|
| sl-card | `SlCard` | Sheet, radius 24, soft shadow, padding 16 |
| sl-ledger / sl-row | `SlLedger`, `SlLedgerRow` | The workhorse list: title, meta, figure or status, optional leading well; hairlines between rows |
| row-ico | `SlIconRow` | Ledger row with an icon well and a chevron (Profile, My farm) |
| ledger-label | `SlGroupLabel` | Capitals label over a ledger |
| sl-tag | `SlTag` / `SlStatusTag` | Tones: good, warn, danger, info, neutral |
| sl-chip | `SlChip`, `SlChoices<T>` | Single choice from a few; selected = shamba-tint fill + shamba border |
| key figure | `SlKeyFigure` | Big figure with caption, on a band |
| sl-ent | `SlEntRow`, `SlEnterpriseTile` | A field, herd or batch with its picture |
| sl-alert | `SlAlertRow`, `SlInfoNote` | Notes with a tinted icon well |
| season strip | `SlSeasonStrip` | The year's rains and today's marker |
| switch | `SlSwitch` | Notification settings |
| sl-btn | `LedgerButton`, `ElevatedButton` (stadium) | Primary is shamba, 56 high, full width at the foot |

### The form kit (`lib/widgets/sl_form.dart`)

Every add form, from screen 28 on, is built from these parts:

- **`SlFormPage`**: a round back button, then an eyebrow over a title, a
  scrolling body, and the primary button pinned at the foot. Errors show in a
  danger-tint box just above the button.
- **`SlField`**: the label (with ` *` if required, `(optional)` if not), the
  control, then a hint or the error under it. Errors replace hints; they don't
  stack.
- **`SlTextBox`**: a 56-high box. The mono face for tags and numbers. It can
  carry a prefix (`KSh`) or a suffix (`acres`, `cows`).
- **`SlSelectBox`**: an icon, the value and a chevron. It opens a picker sheet
  (`slPick`) or a date picker.
- **`SlChoices`**: chips for two to eight options.
- **`SlTypeHead`**: what is being added, with its picture and a "Change" link.
- **`SlLink`**: a quiet secondary action ("Add a building", "Add date of
  birth").

### The record kit (`lib/screens/records/record_form.dart`)

Daily records use `RecordPage` with these parts:

- **`RecordDateField`**: defaults to today.
- **`RecordTally`**: a big figure with − and + steppers, quick-add packs
  ("+10 trays", "+5 litres") and a note on the right ("Yesterday 42.5 litres").
- **`ItemLineFields`**: feed, drug or seed, plus how much and in what unit.

`RecordForm` handles saving: it disables the button while busy, shows field
errors from the API on their own fields, and puts the rest in the banner.

---

## 4. Screens

Numbers match the canvas. Files are under `lib/screens/`.

### Getting in
| # | Screen | File |
|---|---|---|
| 01 | Splash | `onboarding/splash_screen.dart` |
| 02 | Welcome | `onboarding/welcome_screens.dart` |
| 03 | Sign in (phone in Kenya, password elsewhere) | `auth/login_screen.dart` |
| 04 | Verify code | `auth/verify_otp_screen.dart` |
| 04b | Create account (outside Kenya) | `auth/sign_up_screen.dart` |
| 04c | Reset password (sheet) | `auth/forgot_password_sheet.dart` |

### Setting up the farm
| # | Screen | File |
|---|---|---|
| 23b | Set up your farm: name and county | `farm/setup_farm_screen.dart` |
| 05 | Map your farm: walk or draw, or later | `farm/farm_map_screen.dart` |
| 06 | Draw the boundary | ″ |
| 07 | Walk the boundary | ″ |
| 08 | Boundary crosses itself | ″ |
| 09 | Farm mapped | ″ |
| 27 | What are you adding? | `farm/add_to_farm.dart` |

### Every day
| # | Screen | File |
|---|---|---|
| 10 | Home: weather, **Today**, your business, my fields | `home_screen.dart`, `home/` |
| 11 | My fields | `fields/fields_screen.dart` |
| 12 | Field detail | `fields/field_detail_screen.dart` |
| 13 | Record menu | `records/record_menu.dart` |
| 14 | Record the day | `records/record_forms.dart` (`BatchDayForm`, `HerdDayForm`) |
| 15 | Scan with AI | `fields/field_scan_screen.dart` |
| 16 | What the AI found | `fields/scan_result_screen.dart` |
| 17 | Activity | `dashboard/dashboard_screen.dart` |
| 18 | Ask Tulip | `tulip/` |

### Business
| # | Screen | File |
|---|---|---|
| 19 | Customers | `customers/customer_screen.dart` |
| 20 | Sales | `sales/sales_screen.dart` |
| 21 | Vets near you | `vets/vets_screen.dart` |
| 22 | Markets near you | `markets/market_screen.dart` |

### You
| # | Screen | File |
|---|---|---|
| 23 | Profile | `profile/profile_screen.dart` |
| 23a | My farm | `farm/my_farm_screen.dart` |
| 24 | Edit profile | `profile/edit_profile_screen.dart` |
| 25 | Change profile photo | ″ (sheet) |
| 26 | Notifications | `profile/notification_screen.dart` |

### Adding to the farm (from 27)
| # | Screen | File |
|---|---|---|
| 28 | Start a herd | `farm/add_to_farm.dart` (`HerdForm`) |
| 29–34 | Add a dairy cow, beef animal, dairy goat, sheep, pig, rabbit | ″ (`AnimalForm`) |
| — | Quick herd entry: many animals, a row each | `farm/herd_entry.dart` |
| 35–37 | New layers batch, broiler batch, stock a pond | ″ (`BatchForm`) |
| 38–44 | New maize, beans, rice, wheat, tomato, sukuma or spinach season | ″ (`CropForm`) |
| 45–46 | Add bananas, avocados | ″ (`CropForm`, orchard) |
| 47 | Add plot | ″ (`PlotForm`) |
| 48 | Add building or pond | ″ (`StructureForm`) |
| 49 | Add customer | ″ (`CustomerForm`) |
| 50 | Add supplier | ″ (`SupplierForm`) |
| 51 | Invite team member | ″ (`TeamForm`) |

Two built screens aren't on the canvas yet: **Today** (part of Home) and
**Quick herd entry**. Both are built from the kits above. Draw them before
changing them.

---

## 5. Key flows

**New user**
Sign in (03) → Verify code (04) → Complete your profile (modal) → Set up your farm (23b) → Map your farm (05–09,
or "Later") → What are you adding? (27) → Home.
- Complete your profile (`profile/complete_profile_sheet.dart`) asks for name,
  email and phone, and can't be dismissed: Save and continue, or Log out. It
  shows whenever Home opens with an incomplete profile, saved sessions included.
- The setup starts by itself only when the farm list loads and is empty.
- It can also be started from Home, My farm, or any "No farm yet" row.

**Signing in outside Kenya**
Sign in (03) shows a Country field first, defaulting to the last one chosen,
then the phone's region, then Kenya. Kenya signs in with phone + SMS code;
every other country (all 197, searchable by name or code) with username or
email and password. New accounts: Create account (04b) → "Check your email" →
open the emailed link → back to Sign in with the username filled in.
- Google still signs in existing accounts; a new Google account outside Kenya is
  sent to Create account, since finishing it needs an SMS code.

**Returning user, farm not mapped**
Sign in → Home, with Map your farm on top, unless they chose "Later" for that
farm.

**A day's record (the core loop)**
Home → Today → tap a herd → the form opens filled with yesterday's milk, eggs
and feed → adjust → Save.
- This takes two taps when nothing has changed since yesterday.
- Once a herd has a record today, the row shows **Done**, and tapping it again
  adds to the day from an empty form.

**Anything else on a field**
My fields or Field detail → Record (13) → the form for that kind:
- crops: work, harvest, sale, expense
- herds: daily record, milk, feeding, treatment, add animals, weigh, served,
  pregnancy check, birth, sold or died
- batches: daily record, weigh a sample, treatment, sale, expense

**Adding animals**
- Start a herd (28) leads to Quick herd entry, with one row per animal counted.
- One animal at a time uses screens 29–34, which link to Quick herd entry
  ("Adding several?").

---

## 6. Copy

- **Sentence case.** Capitals are for eyebrows only.
- **Say what to do, in the farmer's terms.** "Enter the animal's tag.", not
  "Tag is required."
- **Errors say what is wrong and how to fix it**, in a full sentence ending
  with a full stop.
- **Units the way farmers count:** acres, litres, trays, bags, kg, KSh.
- **Name things by their farm name**, then fall back to the kind of thing:
  "Dairy herd", "Layers, batch 2".
- **Dates:** "Fri 16 Oct 2026" in forms, "16 Oct" in lists, "Today" and
  "Yesterday" when that's what they are.

### Languages

English, Kiswahili and French:
- Every literal shown on screen is written `'…'.tr` or `'…'.trArgs({...})`,
  with entries in `lib/l10n/sw.dart` and `lib/l10n/fr.dart`.
- `test/l10n_test.dart` fails on any missing entry, or any `{placeholder}` that
  doesn't match.
- Ternaries need a `.tr` on each branch, because the test can't see inside them.

---

## 7. Accessibility

- **Contrast:** use the colour pairs in the token table (ink on paper or sheet,
  `onShamba` on `shamba`, each `*Ink` on its `*Tint`). Check any new pair
  against WCAG AA in both themes. `textHint` is not used on `surfaceMuted`.
- **Touch targets:** 44 minimum. Inputs are 56 high, so they work with gloves
  or a thumb.
- **Screen readers:** buttons that only show an icon carry a `Semantics` label
  or tooltip ("Back", "Remove row"). Each tag field in quick herd entry is
  labelled "Tag, row n".
- **Status** is never shown by colour alone.
- **Text scaling:** layouts must hold at 360 wide with long Swahili strings.
  Notes in rows are `Flexible`, and titles wrap to two lines.

---

## 8. Known gaps

- **No offline saving.** Every save needs signal. This is the biggest thing
  still working against "simple".
- **Not yet tested by farmers.** The app hasn't been used by farmers on a real,
  cheap Android phone.
- **Missing from the canvas:** Today and Quick herd entry, as noted in
  section 4.
