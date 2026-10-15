# SeasonStrip

SeasonStrip shows the farming year as Kenya's rains and marks today on it, so every plan and record has a place in the season.

## Anatomy

- Head: the current season as an `eyebrow` in Swahili and English ("VULI · SHORT RAINS") and a `title-m` saying where in it we are ("Week 3 of 10"); a `caption` with the season's advice ("Planting window open").
- Twelve month cells (`radius-s`): rainy months in `season-rain`, dry months in `sheet-sunk`.
- Today's marker: a 3px `maize` line through the strip, and today's month letter in `maize-ink`. This is the system's main use of maize.
- A legend naming masika (long rains, March to May) and vuli (short rains, October to December).

## Provide

Today's date and the season boundaries. Use the county's rain pattern when known (western Kenya has longer rains); the default is the central highlands' two seasons.

## Do and don't

- Do place it at the top of Home and of any crop screen.
- Do label the marker for screen readers ("Today, 15 October").
- Don't add more colours for crop stages; put those in ledger rows below it.
