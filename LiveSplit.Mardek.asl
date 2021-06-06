state("flashplayer32_0r0_142_win_sa") {
  string1000 movieData : 0xC97680;
}

startup {
}

init {
  var parts = current.movieData.Split(',');
  if (parts[1].Contains("Mardek 1")) {
    vars.gameChapter = 1;
  } else if (parts[1].Contains("Mardek 2")) {
    vars.gameChapter = 2;
  } else if (parts[1].Contains("Mardek 3")) {
    vars.gameChapter = 3;
  } else {
    print("Error: .swf file name must contain 'Mardek #'!");
    vars.gameChapter = -1;
    return;
  }
}
