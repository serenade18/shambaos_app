# EnterpriseTile

An EnterpriseTile is one animal group or crop on the farm, with the figure the farmer checks every day.

## Anatomy

- A 48px `shamba-tint` icon well (`radius-s`) holding the animal or crop line icon in `shamba-ink`.
- The name in `label` ("Layers, batch 1", "Maize, short rains") and a `caption` with its size and age ("300 birds · week 34", "2 acres · planted 3 Oct").
- On the right, today's figure in `display` 20px with its unit, or a StatusTag when today has no record yet.
- The whole tile is one link, at least 72px tall.

## Provide

Name, type (for the icon), size line, and today's figure with its unit, from the dashboard's `today` and the enterprise's records.

## Do and don't

- Do call these by what they are in the copy ("Your layers"); the word "enterprise" stays in the code.
- Do order them as the farmer set up their farm, not alphabetically.
- Don't show the catalogue's emoji as the icon.
