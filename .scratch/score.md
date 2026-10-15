## Problem Statement

A player can resolve a chain, but nothing remembers the mass of the chains they have committed. The result written on the head is a rounded power of 2, so the value on the board is not the total the player has earned.

## Solution

The resolve engine keeps a score. Each successful resolve adds the chain's raw sum, the total of its tiles before the result is rounded. The player can read that score. It starts at 0 and grows only when a chain resolves.

## User Stories

1. As a player, I want the score to start at 0, so that a new run has not yet earned anything.
2. As a player, I want to read the score, so that I can see the total of my committed chains.
3. As a player, I want a successful resolve to add the chain's raw sum, so that the score counts the tiles I committed.
4. As a player, I want three 2s to add 6 while the head becomes 8, so that rounding the result does not change what was scored.
5. As a player, I want five 2s to add 10 while the head becomes 16, so that a sum between powers still scores the unrounded total.
6. As a player, I want 2 + 2 to add 4 while the head becomes 4, so that an exact power scores the same number it writes.
7. As a player, I want 2 + 2 + 4 to add 8 while the head becomes 8, so that an exact longer chain scores its sum.
8. As a player, I want forty 2s to add 80 while the head becomes 128, so that a chain of the whole board scores 80.
9. As a player, I want the head's own tile included once in the amount added, so that the last tile counts in the score.
10. As a player, I want the same tiles to add the same amount whichever cell is the head, so that the order of the drag does not change the score.
11. As a player, I want the amount added to equal the raw sum reported by that resolve, so that the report and the score describe one chain.
12. As a player, I want a second resolve to add its own raw sum on top, so that the score is a running total.
13. As a player, I want the score to equal the raw sums of every resolve so far, so that earlier chains are still in the total.
14. As a player, I want a resolve with no open chain to leave the score unchanged, so that a commit needs a chain.
15. As a player, I want a second resolve, with no new seed, to leave the score unchanged, so that one chain is scored once.
16. As a player, I want a refused seed to leave the score unchanged, so that a bad seed earns nothing.
17. As a player, I want a refused step to leave the score unchanged, so that a bad step earns nothing.
18. As a player, I want a step that is accepted to leave the score unchanged until I resolve, so that an open chain is not yet scored.
19. As a player, I want a new seed that replaces an uncommitted chain to leave the score unchanged, so that only a resolve earns.
20. As a player, I want placing a board to leave the score unchanged, so that arranging tiles is not a resolve.
21. As a player, I want placing a board to keep the score I already earned, so that setup does not wipe the total.
22. As a player, I want dealing a board to leave the score unchanged, so that a new fill is not a resolve.
23. As a player, I want dealing a board to keep the score I already earned, so that a fill does not wipe the total.
24. As a player, I want a new engine to start at 0 even when another engine has a score, so that each run total stands on its own.
25. As a player, I want the score to keep growing with no cap, so that a long run can pass any total.

## Implementation Decisions

- The score lives on the resolve engine. The player reads it there. It starts at 0.
- A successful resolve adds that chain's raw sum after the result is chosen, and only that amount. The result written on the head is not the amount added.
- The resolve report still carries the raw sum, the result, and the head cell. The score delta for that resolve equals the reported raw sum.
- A resolve that reports nothing leaves the score unchanged.
- Seed, step, place, and deal do not change the score, whether they succeed or are refused. Place and deal still discard an open chain, as they already do.
- The score is a single running total of raw sums. It is not a best total, and it does not store each chain's sum separately.

## Testing Decisions

- Test the score through the resolve engine. A good test places a known board, seeds, steps, resolves, and reads the score and the resolve report. It does not inspect the addition itself.
- Assert the score before and after each operation. A refused or non-scoring operation leaves the score identical.
- Required cases: three 2s add 6 and report result 8; five 2s add 10 and report result 16; 2 + 2 adds 4; 2 + 2 + 4 adds 8; two successful resolves accumulate; a resolve with no chain, a refused seed, and a refused step leave the score unchanged; place and deal leave an existing score unchanged.
- Follow the existing resolve-engine tests, which place a board, seed a chain, and read the cells. These tests read the score as well. No widget test is part of this spec.

## Out of Scope

- Fall, refill, and the floor. Holes left by a resolve stay empty.
- Clear, and any change to the supply. The supply stays 2, 4, and 8.
- Refresh. The later refresh spec is what leaves this score unchanged when a pairless board is replaced.
- Abandon. The later abandon spec is what discards this score.
- Keeping the score when the app closes.
- Painting the score, and any screen.

## Further Notes

- The score glossary says a refresh leaves the score unchanged and abandoning the run discards it. Those operations are not built here. This spec makes the score change only when a chain resolves, which is what those later specs rely on.
- ADR-0001 fixes the result. The rejected result rules (double the highest tile, round the sum down) are not the score. The score is the raw sum in every case.
- Build this on the resolve engine. It does not require fall, clear, refresh, abandon, or the run store.
