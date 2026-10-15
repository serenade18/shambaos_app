# LedgerRow

A ledger is one `sheet` of ruled rows, each with what it is on the left and its figure on the right, like a page of a farm counter book.

## Anatomy

- **Ledger** (`sl-ledger`): `sheet`, 1px `rule` border, `radius-m`. A head with a `title-m` title and an `eyebrow` period or a quiet "See all" button.
- **Row** (`sl-row`): at least 56px tall, `rule` hairline above it. Left: `label` title and a `caption` meta line. Right: the figure in `figure-s` with its unit in `caption`, and an optional StatusTag below it.
- **Total** (`sl-row--total`): a 3px double `rule-strong` rule above it, bold. Use it only for a real sum of the rows above.
- Codes inside meta (M-Pesa, animal tags) use `sl-code` (`code-s`, mono).

## Provide

Title, meta, the formatted figure with its unit, and an optional status. The whole row is the tap target when it opens a detail screen; add no chevron.

## Do and don't

- Do group related rows into one ledger instead of a card per row.
- Do right-align figures with tabular numerals so they line up.
- Do write quantities in farmer units: "3 bags", "212 trays".
- Don't show a loss by colour alone: minus sign plus a tag or word.
- Don't put more than one status tag on a row.
