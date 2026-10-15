## Problem Statement

A board with no pair ends the player's ability to seed, even though the run is not over. After a resolve, a clear, the fall, and the refill, a pairless board just sits there.

## Solution

When that aftermath leaves no pair, the engine replaces the board before the resolve returns. One tile of the highest value on that board is placed at column 3, row 4. The other 39 cells are drawn from the supply, and that draw is repeated until the board has a pair. The score stays. The replacement is not a resolve and does not clear.

## User Stories

1. As a player, I want a pairless board, after the resolve and its aftermath, to be replaced, so that I can seed again.
2. As a player, I want a board that still has a pair after the refill to stay as it fell, so that a playable board is not replaced.
3. As a player, I want one tile of the highest value kept, so that my best tile survives the replacement.
4. As a player, I want that kept tile at column 3, row 4, so that I know where it rests.
5. As a player, I want column 3 counted from the left and row 4 counted from the top, so that the kept tile sits on the same board I already play.
6. As a player, I want the other 39 cells drawn from the supply, so that the new tiles are values the run has not cleared.
7. As a player, I want the draw repeated until the board has a pair, so that the replacement can be seeded.
8. As a player, I want any fill that has a pair to be enough, so that the board is not searched for the fill with the most pairs.
9. As a player, I want exactly one copy of that highest value kept when several tiles share it, so that the replacement does not mint a second copy of the kept tile.
10. As a player, I want the other tiles of that shared highest value to leave, so that only one is placed at column 3, row 4.
11. As a player, I want my score to stay the same across the replacement, so that a refresh is not a resolve.
12. As a player, I want the resolve report to still be the chain's raw sum, result, and head, so that the replacement does not invent a second result.
13. As a player, I want no value to be cleared by the replacement, so that spawned tiles do not clear.
14. As a player, I want the supply to stay as it was, so that a refresh does not outgrow a value.
15. As a player, I want the open chain to be gone after the resolve that triggered the replacement, so that I seed fresh on the new board.
16. As a player, I want a placed pairless board to stay until a resolve's aftermath is pairless, so that arranging tiles does not refresh.
17. As a player, I want a dealt board to keep its pair and not refresh, so that a deal is not a refresh.
18. As a player, I want the kept tile to be able to sit without a neighboring partner, so that it can wait for a later resolve to produce another tile of its value.
19. As a player, I want a scripted pairless fill to be thrown away and the next fill used, so that I can see the repeat happen.
20. As a player, I want a scripted fill that already has a pair to be the board I read, so that a playable refill is not replaced.

## Implementation Decisions

- Refresh is the last step inside a successful resolve, after the result is written, any clear has run, the survivors have fallen, and the holes have been refilled. It runs only when that board has no pair. There is no separate refresh operation.
- The highest value is the greatest tile value on that pairless board. One tile of that value is placed at column 3, row 4. If several tiles share it, one is kept and the others are not. Tests with a single tile of that value pin which value sits at column 3, row 4.
- The other 39 cells are drawn from the current supply. If the drawn board has no pair, those 39 cells are drawn again. The kept tile stays at column 3, row 4 through every repeat. The first drawn board that has a pair is the board the player reads.
- The optional draw sequence used for refill is also used for these 39-cell draws, in the same order: row 1 through row 8, and within a row column 1 through column 5, skipping column 3, row 4. A scripted value outside the supply is skipped. When the sequence runs out, further cells are drawn at random from the supply, still repeating the 39-cell fill until a pair exists.
- The score does not change. The cleared values and the supply do not change. The resolve report is only the chain that was committed. The open chain is empty when resolve returns.
- A pair among the 39 drawn tiles is enough. A neighboring match for the kept tile is not required. The engine does not mint a second copy of the kept tile.
- Place and deal do not refresh. A pairless placed board stays pairless until a resolve's full aftermath is pairless.
- When the refilled board has a pair, every tile stays where the fall and refill put it, including a high tile that is not at column 3, row 4.

## Testing Decisions

- Test refresh through a resolve on the resolve engine. A good test places a board with one strict highest tile, resolves, feeds a scripted refill, and reads the board, the score, the supply, and the cleared values.
- A script that refills a board with a pair asserts that column 3, row 4 was not specially replaced and that the fallen tiles remain.
- A script whose first 39-cell fill has no pair, and whose next fill does, asserts that the highest value sits at column 3, row 4, the other cells are supply values, the board has a pair, and the first fill was not kept.
- Assert the score, the supply, and the cleared values are identical to their values after the chain was scored and any clear had run. Assert the resolve report is the chain's raw sum, result, and the head cell where the result was written.
- Also assert that placing a pairless board does not move a highest tile to column 3, row 4, and that a dealt board has a pair without a kept-tile placement.
- Follow the existing resolve-engine tests, which place a board, seed a chain, and read the cells. No widget test is part of this spec.

## Out of Scope

- Abandon. A pairless board does not end the run.
- Keeping the refreshed board when the app closes.
- Painting the kept tile, and any screen.
- Choosing the fill with the most pairs.

## Further Notes

- ADR-0002 is this rule. Ending the run at score 0, minting a second copy of the kept tile, and searching the fills for the board with the most pairs were rejected.
- The kept tile usually has no partner, because the supply is the three lowest values not yet cleared. That is allowed.
- ADR-0003 says a refresh does not clear. This spec holds that line.
- Build this on a resolve that already clears, falls, and refills. The pair check happens on the board those steps produced.
