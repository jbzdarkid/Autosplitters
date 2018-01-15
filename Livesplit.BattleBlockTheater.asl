// Animation IDs:
// 0: Standing, changing weapon
// 1: Running
// 2: Ducking
// 3: Falling after double jump
// 4: Teleporting
// 5: Falling after no jump
// 14: Wall sliding
// 15: Drowning
// 18: Water paddle
// 20: Spawning
// 21: Wailing (farting)
// 22: Sliding transition
// 24: Shoving/punching
// 25: Knockback from explosion
// 29: Frog, airplane, discus, grenade, dodgeball, boomerang
// 30: Animation fail (29?)
// 33: On pig and moving
// 34: On pig
// 39: Falling after cat lick
// 40: Landed after cat lick
// 41: Enter level door
// 45: Dodgeball dizzy
// 47: Frozen
// 48: Frozen hop
// 49: Fireball
// 50: Ice
// 51: Falling after single jump
// 53: Vacuum/Fan sustain
// 56: Vacuum/Fan windup
// 57: Sliding
// 58: Throw ready
// 68: Rail climb up
// 71: Rail climb down
// 74: Rail hold facing up
// 77: Rail hold facing down
// 82: Licked by cat
// 88: Poison bubble, dart gun
// 92: Gibbed
// 93: Enter chapter door
// 95: Spring launch
// 98: Energy ball
// 101: Air-spike
// 106: Jet pack flying
// 107: Crying
// 108: Cutscene fadeout?
// 117: Loading & in cage
// 127: Level loading?
// 128: Hatty cutscene

state("BattleBlockTheater") {
  int deathCount  : 0x30E7C4, 0x4B4;
  byte level      : 0x30E7D8, 0x8;
  int inLobby     : 0x30E7D8, 0x28C; // TODO: Improve? I tried.
  bool gameActive : 0x30E7D8, 0x278;
  int loadout     : 0x30ACB0, 0x64, 0x1C0; // TODO: Improve?
  byte animation  : 0x315420, 0x8B;

/*
  byte chapter    : 0x30E7C0, 0x37F6;
  byte gemCount   : 0x30E7C0, 0x37F8;
  string levelName: 0x30E7C0, 0x3860;
  int gameFrames  : 0x315420, 0x8;
  float playerX   : 0x315420, 0x50;
  float playerY   : 0x315420, 0x54;
  int squareX     : 0x315420, 0x270;
  int squareY     : 0x315420, 0x274;
  byte levelWidth : 0x315420, 0x20, 0x109;
  byte levelHeight: 0x315420, 0x20, 0x10A;
*/  
}

startup {
  // Commonly used, default to true
  settings.Add("Split when completing normal levels", true);
  settings.Add("Split when completing secret levels", true);
  settings.Add("Split when completing finale levels", true);
  settings.Add("Split when completing encore levels", true);
  // Less commonly used, default to false
  settings.Add("Split when completing normal levels via secret exit", false);
  settings.Add("Override first text component with a Death Counter", false);
  // For IL runs
  settings.Add("Start when entering a chapter", false);
  settings.Add("Reset when exiting a chapter", false);
}

init {
  vars.deathCount = current.deathCount;

  vars.updateText = false;
  if (settings["Override first text component with a Death Counter"]) {
    foreach (LiveSplit.UI.Components.IComponent component in timer.Layout.Components) {
      if (component.GetType().Name == "TextComponent") {
        vars.tc = component;
        vars.tcs = vars.tc.Settings;
        vars.updateText = true;
        print("Found text component at " + component);
        break;
      }
    }
  }
}

update {
  if (vars.updateText || old.deathCount != current.deathCount) {
    vars.tcs.Text1 = "Death Count:";
    vars.tcs.Text2 = (current.deathCount - vars.deathCount).ToString();
  }
}

start {
  // Start condition 1 (always active):
  // Selected a loadout (0 -> non-0) while the game is not active
  if (old.loadout == 0 && current.loadout > 0) {
    vars.deathCount = current.deathCount;
    print("Started because the player confirmed an initial loadout");
    return true;
  }
  // Start condition 2 (per setting):
  // Entered a chapter from the lobbby
  if (settings["Start when entering a chapter"]) {
    if (current.inLobby != 0) {
      if (old.animation != current.animation && current.animation == 93) {
        print("Started because the player entered a chapter");
        vars.deathCount = current.deathCount;
        return true;
      }
    }
  }
}

reset {
  if (old.gameActive && !current.gameActive) {
    print("Reset because the player returned to the main menu");
    return true;
  }
  if (settings["Reset when exiting a chapter"]) {
    if (old.inLobby == 0 && current.inLobby != 0) {
      print("Reset because the player returned to the lobby");
      return true;
    }
  }
}

split {
  // Don't try to split if the game hasn't loaded in
  if (!current.gameActive) return false;
  if (current.inLobby != 0) {
    if (old.animation != current.animation && current.animation == 4) {
      print("Reached the boat (end of game)");
      return true;
    }
    return false; // Don't try to split otherwise, since we're not in a puzzle
  }
  
  // Grabbed a key or used a teleporter -- only for finale levels because gem count
  // will mess up timings otherwise
  if (old.animation != current.animation && current.animation == 4) {
    // Levels 9-10 (10-11) are the two finales
    if (9 <= current.level && current.level <= 10) {
      print("Completed Finale-"+(current.level-8));
      return settings["Split when completing finale levels"];
    }
  }
  // Changed levels (farted / grabbed secret exit)
  if (current.level > old.level) { // Increased avoids some odd behavior at the beginning
    // Levels 0-8 (1-9) are acts 1-3
    if (0 <= old.level && old.level <= 8) {
      if (current.level == 14) {
        print("Completed level "+(old.level+1)+" via secret exit");
        return settings["Split when completing normal levels via secret exit"];
      } else if (current.level == old.level + 1) {
        print("Completed level "+(old.level+1)+" and proceeded onto the next");
        return settings["Split when completing normal levels"];
      } else if (current.level == 253) {
        print("Completed level "+(old.level+1)+" and returned to lobby");
        return settings["Split when completing normal levels"];
      }
    }
    // Levels 11-13 (12-14) are the encores
    if (11 <= old.level && old.level <= 13) {
      print("Completed Encore-"+(old.level-10));
      return settings["Split when completing encore levels"];
    }
    // Level 14 (15) is the secret level
    if (old.level == 14) {
      print("Completed secret level");
      return settings["Split when completing secret levels"];
    }
  }
}