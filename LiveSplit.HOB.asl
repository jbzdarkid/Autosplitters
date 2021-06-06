state("HOB") {
  float playerX : 0x4A6B164;
  float playerY : 0x4A6B168;
  float playerZ : 0x4A6B16C;
  float level   : 0x4A91444;
}

startup {
  // This runs when LiveSplit starts, and your autosplitter loads.
  // This is where we'll initialize any long-term autosplitter state (e.g., "beaten first boss")
  vars.gameStarted = false;

  vars.levelNames = new Dictionary<float, string> {
    {80.0f, "Grapple Cave"},
    {65.0f, "Overworld"},
    {60.0f, "Water Room"},
    {20.0f, "Warp Cave"},
  };
}

init {
  // This runs when the game starts. This is where you should do any sigscans (...)
  vars.gameStarted = false;
}

start {
  // Called when LiveSplit is trying to determine if the run has started. Return true to start the splits.
  if (!vars.gameStarted) {
    if (Math.Abs(current.playerX - 8.223220825) > 0.1
    || Math.Abs(current.playerY - 25.28863144) > 0.1
    || Math.Abs(current.playerZ + 524.4049072) > 0.1) {
      print("Starting the run because HOB moved from his starting position");
      vars.gameStarted = true;
      return true;
    }
  }
}

isLoading {
  return false;
}

exit {
  print("Game exited, pausing timer");
  timer.IsGameTimePaused = true;
}

reset {

}

