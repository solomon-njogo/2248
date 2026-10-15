## Problem Statement

Tiles of values the player has outgrown stay on the board, and every new tile is still drawn from 2, 4, and 8. A result of 1024 or higher does not yet remove those values or change the supply.

## Solution

The first time a resolve writes a result of 2^k with k at least 10, every tile of each newly crossed lower value leaves. 1024 removes every 2, 2048 removes every 4, 4096 removes every 8, and a result that skips rungs removes every crossed value in that same resolve. Those values leave the supply. The survivors then fall, and the holes refill from the three lowest values the run has not cleared. Cleared tiles add nothing to the score. Until the first 1024, nothing is cleared.

## User Stories

1. As a player, I want a result of 512 or less to clear nothing, so that the board waits for the first 1024.
2. As a player, I want forty 2s, resolving to 128, to clear nothing, so that a chain of the whole board is not yet enough.
3. As a player, I want the first result of 1024 to remove every 2, so that the run has outgrown 2.
4. As a player, I want the first result of 2048 to remove every 4, so that the run has outgrown 4.
5. As a player, I want the first result of 4096 to remove every 8, so that the run has outgrown 8.
6. As a player, I want the next doubling after that to remove the next power of 2, so that each new rung clears one lower value.
7. As a player, I want a first result of 2048 to remove every 2 and every 4, so that a skipped rung is still cleared.
8. As a player, I want a first result of 4096 to remove every 2, every 4, and every 8, so that every crossed value leaves in that resolve.
9. As a player, I want a later result of the same power to leave the board's remaining low tiles alone, so that a threshold fires once.
10. As a player, I want a later higher result to remove only the values not already cleared, so that an old rung is not cleared twice.
11. As a player, I want the result tile itself to stay, so that the value I just wrote is not a cleared value.
12. As a player, I want tiles outside the cleared values to stay, so that a clear removes only the values the result crossed.
13. As a player, I want a chain tile that was already removed by the resolve to count in the raw sum, so that committing a 2 is different from clearing a 2.
14. As a player, I want cleared tiles to add nothing to the score, so that their leaving does not earn.
15. As a player, I want the score to grow by the chain's raw sum alone on a clearing resolve, so that the total ignores every cleared tile.
16. As a player, I want 2 to leave the supply when it is cleared, so that the supply is 4, 8, and 16.
17. As a player, I want 2 and 4 to leave the supply when both are cleared, so that the supply is 8, 16, and 32.
18. As a player, I want 2, 4, and 8 to leave the supply when all three are cleared, so that the supply is 16, 32, and 64.
19. As a player, I want the supply to stay 2, 4, and 8 until the first 1024, so that early resolves still draw the opening values.
20. As a player, I want the holes from a clear to fall and refill before I can seed, so that the next drag is on a full board.
21. As a player, I want that refill to use only the new supply, so that a cleared value is not drawn again.
22. As a player, I want a dealt board after a clear to use the new supply, so that every new tile is one of the three lowest values still in play.
23. As a player, I want a dealt board after a clear to still contain a pair, so that I can seed.
24. As a player, I want placing a tile, even a high one, to clear nothing, so that only a result causes a clear.
25. As a player, I want dealing a board to clear nothing, so that a fill is not a result.
26. As a player, I want a 2 placed after 2s have already been cleared to stay until some later rule removes it, so that a spent threshold does not fire again.
27. As a player, I want to read which values have been cleared, so that I can see what the run has outgrown.
28. As a player, I want to read the three supply values, so that I can see what the next tiles will be.

## Implementation Decisions

- Clear runs inside a successful resolve, after the result is written on the head and the other chain tiles are removed, and before the fall and the refill. The score adds the chain's raw sum and nothing for the cleared tiles.
- A result of 2^k clears only when k is at least 10. The values cleared by that result are 2^(k−9) for every k from 10 through the result's own k that this run has not already cleared. 1024 clears 2, 2048 clears 4, 4096 clears 8, and each further doubling clears the next power of 2.
- The result tile is 2^k with k at least 10, so it is not one of the values removed. It remains, then falls with the other survivors.
- The supply is always the three lowest powers of 2, from 2 upward, that the run has not cleared. It starts at 2, 4, and 8. The engine exposes the supply and the cleared values.
- After the removal, the existing fall packs survivors to row 8 in their column order, and refill fills the holes from the new supply. The optional draw sequence is consumed the same way as in the fall spec. A scripted value outside the current supply is skipped.
- Deal draws from the current supply, still repeating until the board has a pair. Deal and place do not clear. Place may put a value that has already been cleared onto the board; that tile stays until a later resolve whose new threshold names its value. A threshold already recorded does not fire again.
- A result of 512, 256, or 128 records nothing and leaves the supply at 2, 4, and 8.
- Two 512s are a seed whose result is 1024. Two 2048s are a seed whose result is 4096. Tests use seeds like these on a placed board that also holds the low values that should leave.

## Testing Decisions

- Test clear through a resolve on the resolve engine. A good test places the low tiles and the seed, resolves, and reads the board, the score, the supply, and the cleared values.
- Assert which values left, which tiles stayed, that the score rose only by the raw sum, and that scripted refill values are from the new supply and occupy the holes after the fall.
- Required cases: a result of 128 clears nothing; a result of 512 clears nothing; the first 1024 removes every 2 and leaves the supply at 4, 8, and 16; the first result 2048, with nothing cleared before, removes every 2 and every 4; the first 4096 removes every 2, 4, and 8; a second 1024 removes nothing further; a 2048 after 2s were already cleared removes 4s only; a placed 2 after 2s were cleared survives a later resolve that crosses no new threshold; a deal after 2s are cleared uses only 4, 8, and 16 and has a pair; place and deal by themselves clear nothing; the result tile is still on the board after the fall.
- Follow the existing resolve-engine tests, which place a board, seed a chain, and read the cells. No widget test is part of this spec.

## Out of Scope

- Refresh of a pairless board. A board that has no pair after the refill stays that way until the refresh spec.
- Abandon, and keeping the cleared values when the app closes.
- Painting a clear, and any screen.
- Changing the result rule. The result is still the smallest power of 2 greater than or equal to the raw sum.

## Further Notes

- ADR-0003 is this rule. Leaving obsolete tiles on the board, and clearing only one value when a result skipped rungs, were rejected.
- ADR-0001 notes that forty 2s become 128, which is not high enough to clear. That case clears nothing.
- Spawned tiles do not clear. The refresh spec repeats that for a refresh. This spec covers place and deal.
- Build this on a resolve that already falls and refills. The removal happens before that fall.
