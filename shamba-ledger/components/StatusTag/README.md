# StatusTag

A StatusTag names the state of one record in a word, with an icon and a tint, so it reads at a glance and without colour.

## Variants

| Variant | Means | Examples |
| --- | --- | --- |
| `sl-tag--good` | Done, settled | Done, Paid, Vaccinated |
| `sl-tag--warn` | Needs attention soon | Not recorded, Running low, Due Fri |
| `sl-tag--danger` | Act now, money at risk | Below zero, Overdue 12 days, Loss so far |
| `sl-tag--info` | Weather and neutral notices | 34 mm Thu, Synced |
| `sl-tag--neutral` | A fact, not a state | On credit, Cash, M-Pesa |

Each pairs its `-ink` colour with its `-tint` background (4.5:1 or better in both themes). Height 24px, `radius-pill`, `label` text at 12px, a 14px icon.

## Provide

The word (two or three words at most, in sentence case) and the variant. Include the icon for every variant except neutral.

## Do and don't

- Do let the word carry the meaning; the colour only confirms it.
- Don't use tags as buttons or filters (use a chip).
- Don't use maize for a tag.
