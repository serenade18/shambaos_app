# BottomNav

BottomNav holds the four places of the app: Home, Records, Money and Tulip, the farm assistant.

## Anatomy

- 64px tall on `sheet` with a `rule` top border, plus the phone's bottom safe-area inset below it.
- Each item: a 22px line icon over a 12px `label`, in `ink-faint`.
- The current item: `shamba-ink` icon and label, and a 3px `maize` bar on the top edge, the "you are here" mark.

## Provide

The four destinations and which is current. Labels translate (Nyumbani, Rekodi, Pesa, Tulip); allow them to wrap rather than shrink.

## Do and don't

- Do keep exactly four items, always labelled.
- Don't add a floating centre button; Tulip is an item like the others.
- Don't hide the nav while scrolling.
