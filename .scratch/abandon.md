## Problem Statement

A player who wants to stop has no way to end the run. The board, the score, and the values already cleared stay in force. A pairless board must not be the thing that ends the run, and a refresh must not be the thing that discards the score.

## Solution

The player can abandon the run on the resolve engine. Abandon discards the board, the score, and every cleared value, then deals a new board from the opening supply. The score is 0. The supply is 2, 4, and 8. Nothing is cleared. The new board has a pair.

## User Stories

1. As a player, I want to abandon the run, so that I can choose to stop.
2. As a player, I want the score to become 0, so that the next run has not yet earned anything.
3. As a player, I want the old board to be gone, so that I am not still playing those tiles.
4. As a player, I want every cleared value to be forgotten, so that the next run has not outgrown 2.
5. As a player, I want the supply to be 2, 4, and 8 again, so that new tiles are the opening values.
6. As a player, I want a new full board, so that I have somewhere to seed.
7. As a player, I want every tile on that board to be 2, 4, or 8, so that the deal uses the opening supply.
8. As a player, I want that board to contain a pair, so that I can seed immediately.
9. As a player, I want any open chain to be gone, so that a drag from the old run cannot resolve.
10. As a player, I want a resolve after abandon to score only the new chain, so that the discarded total stays discarded.
11. As a player, I want the first 1024 of the new run to be what removes 2s, so that an old clear does not carry over.
12. As a player, I want a 2 on the new board to stay until that new 1024, so that the opening value is in play again.
13. As a player, I want to abandon a second time, so that each run can be ended the same way.
14. As a player, I want abandon to be available when the board has a pair, so that I need not wait for a pairless board.
15. As a player, I want a pairless board to remain a refresh, so that running out of pairs does not discard my score.
16. As a player, I want a refresh to keep the score and the cleared values that abandon would discard, so that the two choices stay different.
17. As a player, I want placing or dealing, without abandoning, to keep my score and my cleared values, so that only abandon ends the run.
18. As a player, I want the resolve report of a chain I already committed to stay the report of that chain, so that abandon does not rewrite it.

## Implementation Decisions

- Abandon is an operation on the resolve engine. It always succeeds when called.
- It sets the score to 0, clears the recorded cleared values, empties the open chain, and deals a new board. The deal uses the opening supply, 2, 4, and 8, fills all 40 cells, and repeats until the board has a pair.
- After abandon, the supply reads 2, 4, and 8, and no value is recorded as cleared. A later result of 1024 is again the first clear of every 2.
- Place and deal do not discard the score or the cleared values. Refresh does not either. A pairless aftermath still refreshes and leaves the score and the cleared values in place.
- Abandon does not produce a resolve report. It does not add to the score before zeroing it. It does not clear tiles by threshold on the way out. The old tiles are simply gone.

## Testing Decisions

- Test abandon through the resolve engine. A good test builds a run with a score, a cleared value, and an open chain, abandons, and reads the score, the supply, the cleared values, the chain, and the board.
- Required cases: the score is 0; no value is cleared; the supply is 2, 4, and 8; all 40 cells hold a tile from that supply; the board has a pair; the open chain is empty; a resolve on the new board adds only that chain's raw sum; a later first 1024 removes 2s again; a second abandon returns to the same opening state; a refresh of a pairless aftermath leaves the score and the cleared values untouched; place and deal leave the score and the cleared values untouched.
- The deal after abandon is judged by those invariants, not by a particular layout.
- Follow the existing resolve-engine tests, which place a board, seed a chain, and read the cells. No widget test is part of this spec.

## Out of Scope

- Keeping the discarded run when the app closes. After abandon, a save would store the new run. That persistence is the run spec.
- Painting an abandon control, and any screen.
- Ending the run because the board has no pair.

## Further Notes

- ADR-0002 says the run ends only when the player abandons it, and that abandoning discards the board, the score, and every clear. Ending on a pairless board was rejected.
- The score glossary says abandoning discards the score. The abandon glossary says the board, the score, and the clears all go.
- Build this on a resolve engine that already scores, clears, falls, refills, and refreshes, so the test can show that refresh keeps what abandon discards.
