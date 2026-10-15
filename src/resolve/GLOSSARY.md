# Resolve

The board a chain is drawn on, and the result a resolve writes on the head.

## The board

**Board**:
The grid a run is played on: 5 columns by 8 rows.
_Avoid_: Grid, field

**Cell**:
One position on the board. It holds at most one tile.

**Tile**:
A power-of-two value occupying a cell, from 2 upward, with no cap.
_Avoid_: Block, number

**Neighbor**:
A cell one king-move away, sharing a side or a corner.
_Avoid_: Adjacent, link

**Pair**:
Two neighboring tiles of equal value.
_Avoid_: Match, link, two-tile link

**Supply**:
The three lowest tile values the run has not cleared. Every new tile is drawn from it.
_Avoid_: Bag, pool, deck

## The chain

**Chain**:
The ordered tiles of the current drag. It never repeats a cell.
_Avoid_: Path, line, link

**Seed**:
The opening pair of a chain.
_Avoid_: Start, match

**Head**:
The last tile in a chain.
_Avoid_: Release point, target, anchor

**Step**:
The addition of one neighboring cell to the head of a chain.
_Avoid_: Move, link

**Resolve**:
The commit of a legal chain.
_Avoid_: Merge, collapse, clear

**Result**:
The value a resolve writes on the head: the smallest power of 2 greater than or equal to the sum of the chain.
_Avoid_: Sum, merge value, ceiling
