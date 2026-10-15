# Sum ceiling

A chain's result is the smallest power of 2 greater than or equal to the sum of its tiles. An exact power stays itself: 2 + 2 + 4 becomes 8. A sum between powers rounds up: three 2s become 8, and five 2s become 16.

## Considered options

- Double the chain's highest tile. Five 2s would become 4, and 2 → 2 → 4 → 8 → 16 would become 32. Chain length would not change the result past the climb.
- Round the sum down to a power of 2. Three 2s would become 4.

## Consequences

The mass of the chain is the economy. The ladder only constrains the route, so a long chain of small tiles can skip several values. Forty 2s sum to 80 and become 128, which is not high enough to clear the board.
