## Problem Statement

After a resolve, the tiles that were in the chain, other than the head, are gone and the cells stay empty. The player cannot keep drawing chains across a closing board, and the empty cells never receive new tiles from the supply.

## Solution

When a resolve removes tiles, the board closes before the resolve returns. In each column, the tiles that remain fall straight down to the floor, keeping their order. The cells that are still empty are then filled from the supply. The player reads one board, already fallen and refilled, and can seed again.

## User Stories

1. As a player, I want the floor to be row 8, so that tiles fall toward the bottom row.
2. As a player, I want row 1 to stay the top, so that a fall moves a tile toward a higher row number.
3. As a player, I want a tile to stay in its column when it falls, so that a fall is straight down.
4. As a player, I want the tiles in a column to keep the order they had from top to bottom, so that a fall does not shuffle them.
5. As a player, I want those tiles packed against row 8, so that holes in the column close.
6. As a player, I want a hole at the top of an already packed column to leave the tiles where they are, so that only real gaps move.
7. As a player, I want a hole in the middle of a column to close, with the empty cell ending up above the packed tiles, so that the survivors sit on the floor.
8. As a player, I want each column to fall on its own, so that a hole in one column does not move another column.
9. As a player, I want the result to fall with the other survivors in its column, so that the head's new value is a tile like any other.
10. As a player, I want the result to leave the cell it was written on when that column still has room below it, so that the report's head cell is the write, not the resting place.
11. As a player, I want a column that lost every tile except the result to rest that result on row 8, so that a lone survivor sits on the floor.
12. As a player, I want a column that lost every tile to be empty after the fall, so that a column fully in the chain, and not holding the head, has nothing left to pack.
13. As a player, I want a full column to look the same after the fall, so that a resolve that missed that column does not shuffle it.
14. As a player, I want the tile values to be unchanged by the fall, so that only their rows change.
15. As a player, I want the empty cells filled from the supply after the fall, so that the board is full before I seed again.
16. As a player, I want each new tile to be 2, 4, or 8, so that refill uses the opening supply.
17. As a player, I want refill to fill only cells the fall left empty, so that a survivor is not replaced.
18. As a player, I want fall and refill to both be done when resolve returns, so that I cannot seed between them.
19. As a player, I want to seed a pair on the closed board, so that I can play the next chain.
20. As a player, I want a refused resolve to leave every tile where it is, so that a commit that does not happen does not fall or refill.
21. As a player, I want placing a board with holes to leave those holes empty, so that I can arrange a column before a resolve.
22. As a player, I want dealing a board to fill every cell without a fall, so that a dealt board is already full.
23. As a player, I want a scripted sequence of supply values to land in the empty cells from top to bottom and left to right, so that I can know which new tile occupies which hole.
24. As a player, I want a chain that removes tiles in several columns to fall in each of those columns, so that a diagonal chain closes the whole board.

## Implementation Decisions

- Fall and refill run inside a successful resolve, after the result is written on the head and the other chain tiles are removed, and before the resolve returns. There is no separate fall operation.
- The floor is row 8. Columns are 1–5 from the left. Rows are 1–8 from the top. A tile never changes its column.
- In each column, list the remaining tiles from row 1 toward row 8. Write them back into that same column, packed against row 8, in that same order. The topmost survivor stays above the others.
- Refill then fills every cell that is still empty. The opening supply is 2, 4, and 8. Each new tile is one of those values.
- The engine accepts an optional sequence of tile values. Refill consumes that sequence in order. The first value lands on the empty cell with the lowest row number, and within a row the lowest column number, then the next empty cell in that order. A scripted value that is not in the current supply is skipped. When the sequence runs out, further holes are drawn at random from the supply.
- Place does not fall or refill. A placed hole stays empty until a later resolve. Deal fills all 40 cells from the supply and does not fall. Deal still repeats until the board has a pair.
- The resolve report still names the head cell where the result was written, plus the raw sum and the result. That cell may be empty after the fall. The board read after resolve shows the resting tiles and the refill.
- A refused resolve, a refused seed, and a refused step do not fall or refill.

## Testing Decisions

- Test fall through a resolve on the resolve engine. A good test places a known column, resolves a known chain, and reads every cell. It does not inspect a packing helper.
- Assert the order of survivors against row 8, that each survivor kept its column and its value, and that scripted refill values occupy the holes in row-then-column order.
- Required cases: a hole in the middle of one column; a hole only at the top of a packed column; two columns where only one lost a tile; a result that rests lower than the head cell named in the report; a column left empty because it held chain tiles and not the head; a full column left untouched; a refused resolve that moves nothing; a placed hole that stays empty until a resolve; a scripted refill of 2, 4, and 8 into known holes.
- Follow the existing resolve-engine tests, which place a board, seed a chain, and read the cells. No widget test is part of this spec.

## Out of Scope

- The running score. A resolve may already add the raw sum; this spec does not change that rule.
- Clear, and any change to the supply. Refill stays on 2, 4, and 8.
- Refresh of a pairless board. A refilled board is left as it is, even when it has no pair.
- Abandon, and keeping the run when the app closes.
- Painting the fall, and any screen.

## Further Notes

- ADR-0003 describes this same fall and refill after a clear. The clear spec is what removes outgrown values first and then refills from the new supply. Until that spec, nothing is cleared.
- The resolve spec left chain cells empty on purpose. This spec is the change that closes them before resolve returns.
