# Autosplitters
Speedrunners like to have splits to keep track of how well they're doing, compared to previous runs. Autosplitters facilitate this by splitting *for* the runner, so they can focus their attention on the game. Unfortunately, these do not spring from the ground fully formed, they have to be written! I've been slowly amassing a few of these that I wrote, and I'm collecting them here so I don't lose track of them all.

[https://github.com/LiveSplit/LiveSplit/blob/master/LiveSplit.AutoSplitters.xml](AutoSplitters.xml)

# [The Talos Principle](LiveSplit.TheTalosPrinciple.asl)
- Starts on new game
- Load removal for intro cutscene, restart checkpoint, and level transitions
- Splits for sigils, exiting worlds, arranger interactions, end of game, and many custom settings
- Resets on game exit

# [The Witness (v2)](LiveSplit.TheWitness2.asl)
- Starts on first movement
- Splits for panels, EPs, panel subsets
- Resets on new game
- Option to count failed panels

# [Braid](LiveSplit.Braid.asl)
- Starts after countdown
- IGT to cut out load times
- Splits for puzzle pieces, level transitions
- Resets on new game

# [Battleblock Theater](LiveSplit.BattleBlockTheater.asl)
- Starts on loadout select, or chapter entry (per setting)
- Splits on level transition / key grab
- Resets on returning to main menu, or chapter exit (per setting)
- Option to count player deaths

# [FEZ](LiveSplit.FEZ.asl)
- Starts on new game
- IGT to cut out load times
- Splits on level transitions, specific game locations (per setting), and end of game
- Resets when starting a new run
- Option to count player deaths

# [Return of the Obra Dinn](LiveSplit.ObraDinn.asl)
- Starts 2s late
- Splits on scene transitions, end of chapter, and end of game

# [Parallax](LiveSplit.Parallax.asl)
- Starts on loading into A1
- IGT to cut out score screens
- Splits on level transitions
- Resets on timer reset
- Option to count level resets and player deaths
