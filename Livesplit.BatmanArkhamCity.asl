state("BatmanAC") {
  float copyPlayerX : 0x1519868;
  float copyPlayerY : 0x151986C;
  float copyPlayerZ : 0x1519870;
  int chapter : 0x1181A9C;
  bool gameActive : 0x151ECA4;
}

startup {
  settings.Add("Override first text component with debug information", false);
  
  vars.chapters = new Dictionary<int, string>{
    {350, "Penguin Fight Done"},
    {355, "Suited Up"},
    {360, "Objection! Overruled."},
    {370, "Exit Courthouse"},
    {385, "Attacking armed thugs head on is suicide."},
    {457, "There's the gun."},
    {491, "Clock Tower Explodes"},
    {533, "AR Training 1 Start"},
    {543, "AR Training 1 Done"},
    {552, "AR Training 2 Done"},
    {558, "Grapnel Boost dropped"},
    {559, "AR Training 3 Done"},
    {577, "I need to find a route into the steel mill"},
    {579, "Grapnel Boost collected"},
    {580, "Listen up dumb-asses, and listen carefully"},
    {594, "After steel mill slide"},
    {635, "After quick batarang"},
    {665, "Enter Smelting Chamber"},
    {670, "Enter Assembly Line"},
    {695, "Free Doctor"},
    {718, "Enter Assembly Line post-weld"},
    {731, "I'll be in touch...!"},
    {734, "Enter GCPD"},
    {743, "Enter Museum"},
    {745, "Exit Museum"},
    {750, "Destroy Jammer 1"},
    {751, "Destroy Jammer 3"},
    {812, "~Something out of bounds"},
    {826, "Enter Solomon Grundy Fight"},
    {827, "Re-Enter Torture Chamber (?)"},
    {844, "Exit freeze (?)"},
    {851, "Enter Wonder Tower Foundation"},
    {872, "(?)"},
    {873, "New Objective: Return to the GCPD lab"},
    {883, "Exit Ra's (?)"},
    {890, "Freeze fight complete"},
    {902, "Enter Amusement Mile"},
    {915, "Enter Train yard"},
    {916, "Save Vicki Vale"},
    {925, "Hack Tyger Helicopter"},
    {933, "New Objective: Gain Access to Wonder Tower"},
    {935, "Enter Collapsed Streets"},
    {942, "Elevator arrives at observation deck"},
    {950, "Oracle, shut this place down"},
    {990, "Enter Clayface fight"},
    {1013, "NG+"}
  };
  foreach(var chapter in vars.chapters) {
    settings.Add(chapter.Value, false);
  }
}

init {
  vars.updateText = false;
  vars.tcs = null;
  if (settings["Override first text component with debug information"]) {
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
  if (vars.tcs != null && (vars.updateText || old.chapter != current.chapter)) {
    vars.tcs.Text1 = ""+current.chapter;
    vars.tcs.Text2 = vars.chapters[current.chapter];
  }
}

start {
  if (old.chapter == 347 && current.chapter == 348) return true;
}

reset {
  if (old.gameActive && !current.gameActive) return true;
}

split {
  if (old.chapter != current.chapter) {
    print(old.chapter+" "+current.chapter);
    string name = vars.chapters[current.chapter];
    if (settings[name]) return true;
  }
}
