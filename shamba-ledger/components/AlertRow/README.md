# AlertRow

An AlertRow tells the farmer about one thing on the farm that needs them, in one sentence, with the action to take.

## Anatomy

- A 40px icon well (`radius-s`) in the severity's tint and ink: `danger` (overdue, below zero), `warn` (due soon, low stock, debts), `info` (weather).
- The sentence in `body`, written from the API's alert type and parameters: "Newcastle vaccine due for Layers, batch 1 by Fri 23 Oct."
- A foot line with a StatusTag for timing and one quiet link for the action ("Record vaccination", "See forecast", "Send reminder").
- Rows sit inside a ledger titled "Needs you", most urgent first.

## Provide

The alert type, severity and parameters from `/dashboard` `alerts`, the worded sentence, and where the action goes.

## Do and don't

- Do name the animal, field or person and the date in the sentence.
- Do drop an alert from the list once its condition passes.
- Don't show more than five on Home; link to the rest.
- Don't use red for weather. Rain is information, shown in `rain`.
