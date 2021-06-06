state("PsychonautsInTheRhombusOfRuin-Win64-Shipping") {
  float x: 0x28BB398;
  float y: 0x28BB39C;
  float z: 0x28BB3A0;
}

startup {
  vars.chapters = new List<Tuple<float, float, float>>(){
    new Tuple<float, float, float>(-31,   37,     0     ), // Menu
    new Tuple<float, float, float>(-42,   -19845, 282   ), // Tutorial
    new Tuple<float, float, float>(-5859, 9261,   -20227), // Tracking Truman
    new Tuple<float, float, float>(-5912, 8979,   -20557), // Charlie Psycho Delta
    new Tuple<float, float, float>(-537,  -3992,  7130  ), // Milla's Mistake
    new Tuple<float, float, float>(-5338, -2728,  9257  ), // Gunpowder Garden
    new Tuple<float, float, float>(-5883, -2360,  10825 ), // Lili's Locomotive
    new Tuple<float, float, float>(-585,  579,    18351 ), // Periscope of Peril
    new Tuple<float, float, float>(-998,  -4055,  19235 ), // Sasha's Spaceship
    new Tuple<float, float, float>(12500, 9076,   17867 ), // Coach's Cruise
    new Tuple<float, float, float>(-5912, 8979,   -20557), // Invasive Procedures
    new Tuple<float, float, float>(-3,    378,    542   ), // Loboto's Leviathan
    new Tuple<float, float, float>(39880, 0,      0     ), // Little House in the Psyche
    new Tuple<float, float, float>(-5912, 8979,   -20557), // Ruin
    new Tuple<float, float, float>(0,     0,      0     )  // Credits
  };
  vars.chapter = 0;
}

reset { // ????!!!
  return false;
  var menu = vars.chapters[0];
  if (Math.Abs(current.x - menu.Item1) < 100 &&
      Math.Abs(current.y - menu.Item2) < 100 &&
      Math.Abs(current.z - menu.Item3) < 100) {
    // Entered the menu
    print("Entered the menu, resetting");
    vars.chapter = 0;
    return true;
  }
}

start {
  var tutorial = vars.chapters[1];
  if (Math.Abs(current.x - tutorial.Item1) < 100 &&
      Math.Abs(current.y - tutorial.Item2) < 100 &&
      Math.Abs(current.z - tutorial.Item3) < 100) {
    // Entered the tutorial
    print("Entered JetFigment, starting run");
    vars.chapter = 1;
    return true;
  }
}

split {
  for (var i=vars.chapter; i<vars.chapter+2; i++) {
    if (Math.Abs(current.x - vars.chapters[i].Item1) < 100 &&
        Math.Abs(current.y - vars.chapters[i].Item2) < 100 &&
        Math.Abs(current.z - vars.chapters[i].Item3) < 100) {
      print(current.x + " " + current.y + " " + current.z);
      if (i == vars.chapter) return false; // Still in the current chapter
      print(vars.chapters[i].Item1 + " " + vars.chapters[i].Item2 + " " + vars.chapters[i].Item3);
      print("Entered chapter " + i);

      // Note that we might be a few chapters ahead.
      // Since there's no way to skip splits in an autosplitter,
      // we simply run this loop over and over until we reach the target chapter.
      vars.chapter++;
      return true;
    }
  }
}