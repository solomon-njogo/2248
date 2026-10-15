# Refresh instead of ending

A board with no pair does not end the run. After a resolve, any clear, the fall, and the refill, that board is replaced. The score stays. One tile of the highest value is placed at column 3, row 4 (columns 1–5 from the left, rows 1–8 from the top). The other 39 cells are drawn from the supply, and the draw is repeated until the board has a pair. The run ends only when the player abandons it.

## Considered options

- End the run and start the next one at score 0.
- Mint a second copy of the kept tile so it can be chained immediately.
- Search the random fills for the board with the most pairs.

## Consequences

The kept tile usually has no partner, because the supply is the three lowest values not yet cleared. It sits at column 3, row 4 until a later resolve produces another tile of its value. Closing the app keeps the open run. Abandoning discards the board, the score, and every clear.
