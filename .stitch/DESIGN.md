# Design System: 2248

## 1. Visual Theme & Atmosphere

2248 is a bright phone puzzle on a deep navy field. The board is five columns by eight rows, and the bottom row is the floor. Tiles are saturated, softly rounded squares. Each power of two has its own color, and the numeral is bold white. The player draws a chain through neighboring cells, including corners. Tiles on that chain turn violet, pick up a white rim, and join with a thick connector. The chain never repeats a cell.

The mood is a saturated casual puzzle: a full rainbow on every board, tight spacing, chunky type. Neighboring values sit on opposite sides of the color wheel, so 2, 4, and 8 never share a warm family. It is still 2248. There is no gem wallet, no level, no goal track, no hammer, and no crown. The score is the running total of raw sums. The supply is the three lowest values the run has not cleared.

## 2. Color Palette & Roles

### Primary Foundation
- **Night Field (`#1a1464` to `#3a1268` to `#0e3a4a`)**: A vivid indigo-plum-teal gradient. The page itself is colorful, not a flat navy.
- **Well (`#24185a`)**: The board's inset. Empty cells sit here.
- **Floor (`#1a1048`)**: The bottom row only, a deeper band of the same gradient.
- **Chip (`#2a1d78`)**: Score and supply holders. The rim is a magenta-to-cyan gradient, `#ff2d8a` into `#19e0ff`.

### Tile ladder
White numerals on every tile, except Lemon and Lime, which use Ink so the digits stay readable. Each step of the ladder jumps to a distant hue.
- **2 Magenta (`#ff2d8a`)**
- **4 Cyan (`#19e0ff`)**
- **8 Lime (`#c6f22a`)**
- **16 Orange (`#ff7a18`)**
- **32 Blue (`#3d6bff`)**
- **64 Lemon (`#ffe14a`)**
- **128 Purple (`#b44dff`)**
- **256 Red (`#ff4d4d`)**
- **512 Mint (`#2ef2a0`)**
- **1024 Hot Pink (`#ff4fd8`)**

Higher powers keep walking the wheel. A value never sits next to a similar hue.

### Accent & Interactive
- **Chain Violet (`#9b5cff`)**: Fill of every tile in the open chain, whatever its value. It has to outshine the rainbow.
- **Chain Line (`#ffffff`)**: The connector and the rim on chain tiles. About 6px, round joins.
- **Result Gold (`#ffe14a`)**: The head's fill at the moment of resolve, with Ink numerals.

### Typography & Text Hierarchy
- **White (`#ffffff`)**: Wordmark, tile numerals, score, dialog title.
- **Mist (`#b7b7d6`)**: Labels: Score, Supply, Refresh, footnotes.
- **Ink (`#1a1a2e`)**: Text on Lime and Lemon. Abandon's confirmation button uses Magenta with white text.

### Functional States
- **Open chain**: Chain tiles are Chain Violet with a white rim and a white connector through their centers, including a diagonal step. The head's rim is slightly thicker.
- **Resolve**: The head becomes Result Gold and shows the result. Consumed cells are empty wells.
- **Clear**: Outgrown tiles are gone. Their cells are empty wells. No strike-through.
- **Refresh**: The board is full. The kept tile uses its ladder color and nothing else marks it.
- **Abandon**: A Night Field scrim. The dialog is Chip-colored, rounded, with a Coral filled button and an outline button.

## 3. Typography Rules

- **Plus Jakarta Sans** for everything, including numerals. One family, heavy where the number is the content.
- Wordmark `800` at `28px/32px`.
- Dialog title `700` at `22px/28px`.
- Tile numerals `800`, white, sized to the cell, tight tracking.
- Score figure `800` at `22px/28px`, tabular.
- Labels `700` at `11px/16px`, `0.08em` tracking, uppercase, Mist.
- Body and footnotes `500` at `14px/20px`, Mist.

## 4. Component Stylings

- **Tile**: Square, `16px` radius, value color as fill, white numeral centered. A soft inner highlight on the top edge. No icon, no badge, no suffix.
- **Cell**: `8px` gap between tiles. An empty cell is a Well square with the same radius, no numeral.
- **Chain**: Tiles on the chain switch to Chain Violet. A `6px` white connector runs center to center, over the gaps, with round caps. Diagonal steps are allowed.
- **Supply**: Label Supply, then exactly three small tiles in their ladder colors.
- **Score**: A Chip on the right of the header. Label Score, then the figure in white. It is the running total of raw sums.
- **Buttons**: `48px` minimum height, `16px` radius. The in-play Abandon control is Mist text under the board. In the dialog, Abandon is Coral with white text. Keep playing is a white outline on a transparent fill.
- **Dialog**: Chip surface, `24px` radius, `24px` padding, white title, Mist body. No glass blur.

## 5. Layout Principles

- **Board**: Always 5 columns by 8 rows. Columns 1–5 from the left. Rows 1–8 from the top. Row 8 is the floor. Never 4 by 4, never 6 columns.
- **Grid & Spacing**: `8px` baseline. `16px` screen padding. `8px` between tiles. `20px` between header, supply, board, and the Abandon control.
- **Mobile**: Portrait. The board uses the full width inside the padding. Header is one row: 2248 at the left, the Score chip at the right. Supply sits under the header.
- **Desktop**: The same portrait board is centered on the Night Field. Maximum board width `420px`. No side navigation and no extra panels.
- **Touch**: Every tile is a drag target. The chain is the gesture. There is no swipe control and no directional pad.

## 6. Design System Notes for Stitch Generation

- **Atmosphere keywords**: Vivid indigo-plum field, rainbow rounded tiles, magenta cyan and lime side by side, violet chain with a white connector, casual phone puzzle.
- **Vocabulary**: Board, cell, tile, neighbor, pair, chain, seed, head, step, resolve, result, score, supply, clear, refresh, abandon, run, floor. Never say grid, block, match, path, merge, points, high score, level, session, restart, or game over.
- **Leave out**: gems, coins, a level badge, a goal bar, crowns, hammers, undo, pause, and letter suffixes on numbers.
- **Component prompts**: A 5 by 8 board of color-coded rounded tiles on navy; an open chain recolored violet and joined by a white stroke; a three-tile supply; a score chip; a navy dialog whose filled button is Abandon.
