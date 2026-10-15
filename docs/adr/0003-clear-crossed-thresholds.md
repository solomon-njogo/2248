# Clear crossed thresholds

The first time a run writes a result of 2^k with k ≥ 10, every tile of value 2^(k−9) is removed. 1024 clears every 2, 2048 clears every 4, 4096 clears every 8, and each further doubling clears the next power of 2. A single result that skips rungs clears every crossed value in that resolve. Cleared tiles add nothing to the score. Each cleared value leaves the supply, which is always the three lowest values the run has not cleared.

## Considered options

- Change only which values spawn, and leave obsolete tiles on the board.
- Clear one value per resolve even when the result skipped rungs. A jump straight to 4096 would remove the 2s and never come back for the 4s and 8s.

## Consequences

Survivors fall straight down in their existing order, then the holes are filled from the new supply before the player can drag. Spawned tiles, including a refresh, do not fire a clear. Until the first 1024, nothing is cleared.
