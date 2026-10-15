# Glossary Map

2248 is one puzzle in seven contexts, in the order a run is built.

## Contexts

- [Resolve](./src/resolve/GLOSSARY.md): the board and the chain that resolves into a result
- [Score](./src/score/GLOSSARY.md): the raw-sum total of a run
- [Fall](./src/fall/GLOSSARY.md): the floor, the fall, and the refill that close the board
- [Clear](./src/clear/GLOSSARY.md): removal of values the run has outgrown
- [Refresh](./src/refresh/GLOSSARY.md): replacement of a pairless board
- [Abandon](./src/abandon/GLOSSARY.md): the player's choice to end the run
- [Run](./src/run/GLOSSARY.md): one continuous play, kept when the app closes

## Relationships

- **Resolve → Score**: A resolve feeds Score the chain's raw sum. The result is the value written on the head.
- **Resolve → Fall**: Tiles a resolve removes are closed by Fall and then Refill, drawn from Supply.
- **Resolve → Clear**: Only a Result causes a Clear. Cleared values leave the Supply.
- **Fall → Refresh**: Refresh runs when the board has no Pair after Fall and Refill.
- **Score → Refresh**: A refresh leaves the Score unchanged.
- **Score → Abandon**: Abandon discards the Score.
- **Abandon → Run**: Abandon is the only way a Run ends. Closing the app keeps the open Run.
