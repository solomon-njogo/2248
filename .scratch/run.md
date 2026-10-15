## Problem Statement

The board, the score, and the values a run has cleared exist only inside a live engine. Discarding that engine loses the run. Closing the app would end a run the player did not abandon.

## Solution

A store keeps the open run. The player saves the engine into the store and loads it into a new engine. The new engine shows the same board, the same score, the same cleared values, and the same open chain. The supply follows the cleared values. Loading is not an abandon, and it is not a resolve.

## User Stories

1. As a player, I want to close the app and come back to the same board, so that closing does not end the run.
2. As a player, I want the same tile in every cell after I come back, so that the board is the one I left.
3. As a player, I want empty cells to stay empty, so that a hole I had placed is still a hole.
4. As a player, I want my score to be the same, so that closing does not discard what I earned.
5. As a player, I want the values I have cleared to be the same, so that the run still remembers what it outgrew.
6. As a player, I want the supply to be the three lowest values I have not cleared, so that the next draw matches the run I left.
7. As a player, I want an open chain to still be open, in the same order, with the same head, so that a drag in progress is still my drag.
8. As a player, I want to resolve that restored chain, so that I can finish the drag I left.
9. As a player, I want a run with no open chain to come back with no open chain, so that a finished drag stays finished.
10. As a player, I want a new engine with nothing saved to stay as it is when I load, so that an empty store does not invent a board.
11. As a player, I want a second save to replace the stored run, so that the store keeps the latest play.
12. As a player, I want a load to replace whatever board, score, clears, and chain the target engine had, so that I come back to the stored run and not a mix.
13. As a player, I want loading to leave the stored run in the store, so that I can load it again.
14. As a player, I want loading to add nothing to the score, so that coming back is not a resolve.
15. As a player, I want loading to clear nothing, so that coming back is not a result.
16. As a player, I want loading to deal nothing, so that a partial board is not filled in behind my back.
17. As a player, I want to abandon, save, and come back to the new run, so that a discarded run stays discarded.
18. As a player, I want the old score and the old clears to be gone after that, so that abandon still ends the run even when the app closes afterward.
19. As a player, I want two loads of one save to show the same board and score, so that the stored run does not change when it is read.
20. As a player, I want a resolve I commit after saving, and do not save again, to be absent when I load, so that the store keeps the save and not the later play.

## Implementation Decisions

- One store sits beside the resolve engine. Saving copies the engine's board, score, cleared values, and open chain into the store. The supply is not copied on its own. It is the three lowest powers of 2 from 2 upward that are not among the cleared values, and a load restores it by restoring those cleared values.
- Loading into an engine replaces that engine's board, score, cleared values, and open chain with the stored run. If the store has no run, the load leaves the engine unchanged and reports that nothing was kept.
- A load does not resolve, deal, fall, refill, clear, refresh, or abandon. It does not add to the score.
- Discarding the engine and loading into a fresh one is the stand-in for closing the app and opening it. Tests use an in-memory store.
- Saving after abandon stores the new run: score 0, no cleared values, the dealt board, and no open chain.
- A later resolve on the live engine does not change the store until the next save.

## Testing Decisions

- Test the store by saving one engine and loading into another, then reading the board, the score, the supply, the cleared values, and the chain. A good test compares those reads. It does not inspect the stored bytes.
- Required cases: a board with holes, a score above 0, a cleared value, and an open chain all survive; a run with no open chain comes back with no chain; an empty store leaves the target engine unchanged; a second save replaces the first; a load does not change the score or the cleared values beyond restoring them; loading twice yields the same reads; abandon, then save, then load, yields score 0, the opening supply, and a full board from 2, 4, and 8; a resolve after a save is absent on load until a new save.
- The restored chain can be resolved, and the score grows by that chain's raw sum from the restored total.
- Follow the existing resolve-engine tests, which place a board, seed a chain, and read the cells. No widget test is part of this spec, and no test has to kill the process.

## Out of Scope

- Painting a screen, and any real app shutdown.
- A second run kept beside the open one. The store holds the open run only.
- Changing what abandon discards. Abandon still ends the run. The store only keeps whatever the engine holds after that.

## Further Notes

- The run glossary says a run ends only when the player abandons it, and closing the app does not end it. ADR-0002 records the same consequence.
- Build this on an engine that already scores, clears, and abandons, so the saved run has something to restore and the abandoned run has something to forget.
