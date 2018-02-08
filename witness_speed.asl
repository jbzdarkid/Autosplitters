state("witness64_d3d11") {
  float x  : 0x5B5528;
  float y  : 0x5B552C;
  float z  : 0x5B5530;
  double t : 0x5A6C30;
  // float x  : 0x62D490;
  // float y  : 0x62D494;
  // float z  : 0x62D498;
  // double t : 0x61E1D0;
}

init {
  vars.x = 0;
  vars.y = 0;
  vars.z = 0;
  vars.t = 0;
  
  var data = new Dictionary<int, Tuple<int, string>> {
    {0x30B0, new Tuple<int, string>(0x0D8, "Audio Marker")},
    {0x30F0, new Tuple<int, string>(0x0C8, "Audio Recording")},
    {0x3150, new Tuple<int, string>(0x000, "Boat")}, // Singleton at 0x30
    {0x31B0, new Tuple<int, string>(0x000, "Bridge")},
    {0x31F0, new Tuple<int, string>(0x000, "Cloud")},
    {0x3230, new Tuple<int, string>(0x000, "Cluster")},
    {0x3270, new Tuple<int, string>(0x000, "Collision Path")},
    {0x32B0, new Tuple<int, string>(0x000, "Collision Volume")},
    {0x3300, new Tuple<int, string>(0x150, "Color Marker")},
    {0x3380, new Tuple<int, string>(0x168, "Door")},
    {0x33C0, new Tuple<int, string>(0x000, "Double Ramp")}, // Singleton at 0x387A
    {0x3480, new Tuple<int, string>(0x000, "Fog Marker")},
    {0x35E0, new Tuple<int, string>(0x058, "Force Bridge")},
    {0x3620, new Tuple<int, string>(0x000, "Force Bridge Segment")},
    {0x3660, new Tuple<int, string>(0x000, "Force Field")}, // Singleton at 0x17BC4
    {0x36A0, new Tuple<int, string>(0x000, "Gauge")},
    {0x3720, new Tuple<int, string>(0x0C8, "Grass Chunk")},
    {0x3760, new Tuple<int, string>(0x058, "Group")},
    {0x37A0, new Tuple<int, string>(0x000, "Human")}, // Singleton at 0x1E465
    {0x3800, new Tuple<int, string>(0x0E0, "Inanimate")},
    {0x3840, new Tuple<int, string>(0x0C8, "Issued Sound")},
    {0x38D0, new Tuple<int, string>(0x000, "Landing Signal")} ,
    {0x3880, new Tuple<int, string>(0x000, "Lake")},
    {0x3910, new Tuple<int, string>(0x058, "Laser")},
    {0x3990, new Tuple<int, string>(0x0E8, "Light")},
    {0x39D0, new Tuple<int, string>(0x000, "Light Probe")},
    {0x3A10, new Tuple<int, string>(0x220, "Machine Panel")},
    {0x3A90, new Tuple<int, string>(0x0D8, "Marker")},
    {0x3B60, new Tuple<int, string>(0x0D0, "Multipanel")},
    {0x3BA0, new Tuple<int, string>(0x0D8, "Note")},
    {0x3BE0, new Tuple<int, string>(0x000, "Obelisk")},
    {0x3C20, new Tuple<int, string>(0x058, "Obelisk Report")},
    {0x3C60, new Tuple<int, string>(0x000, "Occluder")},
    {0x3D30, new Tuple<int, string>(0x1B0, "Particle Source")},
    {0x3D70, new Tuple<int, string>(0x0C8, "Pattern Point")},
    {0x3DD0, new Tuple<int, string>(0x1A8, "Power Cable")},
    {0x3E10, new Tuple<int, string>(0x0C8, "Pressure Plate")},
    {0x3E50, new Tuple<int, string>(0x0C8, "Pylon")},
    {0x3E90, new Tuple<int, string>(0x0D8, "Radar Item")},
    {0x3ED0, new Tuple<int, string>(0x220, "Record Player")}, // Singleton at 0xBFF
    {0x3F50, new Tuple<int, string>(0x0D8, "Slab")},
    {0x3F90, new Tuple<int, string>(0x058, "Speaker")},
    {0x40A0, new Tuple<int, string>(0x000, "Terrain Guide")},
    {0x4120, new Tuple<int, string>(0x000, "Video Player")}, // Singleton at 0x3B6
    {0x41A0, new Tuple<int, string>(0x0D0, "Video Screen")},
    {0x4220, new Tuple<int, string>(0x058, "Waypoint Path3")},
    {0x42A0, new Tuple<int, string>(0x000, "World")}, // Singleton at 0x12508
  };
  
  double bestDist = 99999.0;
  string best = "";
  for (int i=0; i<0x3FFFF; i++) {
    var type = (new DeepPointer(0x5B28C0, 0x18, i*8, 0x8)).Deref<int>(game) - 0x405B0000;
    if (type < 0) continue;
    if (!data.ContainsKey(type)) continue;
    if (type != 0x3DD0) continue;
//    float x = (new DeepPointer(0x5B28C0, 0x18, i*8, 0x24)).Deref<float>(game);
//    float y = (new DeepPointer(0x5B28C0, 0x18, i*8, 0x28)).Deref<float>(game);
//    float z = (new DeepPointer(0x5B28C0, 0x18, i*8, 0x2C)).Deref<float>(game);

//    float dx = x - 150;
//    float dy = y + 65;
//    float dz = z - 49;
//    double dist = Math.Sqrt(dx*dx+dy*dy+dz*dz);
    
    string name;
    if (data[type].Item1 != 0x000) {
      var namePtr = new StringWatcher(new DeepPointer(0x5B28C0, 0x18, i*8, data[type].Item1, 0), 100);
      namePtr.Update(game);
      name = namePtr.Current;
    } else {
      name = "";
    }
    if (name == "lotus_start_scramble")
/*    if (dist < bestDist) {
      best = i.ToString("X")+" ("+data[type].Item2+") : "+name;
      bestDist = dist;
    }*/
    print(i.ToString("X")+" ("+data[type].Item2+") : "+name);
  }
//  print(best);
//  print("dist: "+bestDist);
  vars.ints = new int[1000];
}

update {
  string updated = "";
  for (int i=0; i<1000; i+=4) {
    int val = (new DeepPointer(0x5B28C0, 0x18, 0x9E54*8, i)).Deref<int>(game);
    if (vars.ints[i] != val) {
      updated += i.ToString("X")+" ";
      vars.ints[i] = val;
    }
  }
  if (updated != "") {
    print(updated);
  }
  
  if (current.t - vars.t > 1.0) {
    float dx = current.x-vars.x;
    float dy = current.y-vars.y;
    float dz = current.z-vars.z;
    double dt = current.t-vars.t;
    //print("1D motion: "+(Math.Abs(dx)/dt));
    //print("2D motion: "+(Math.Sqrt(dx*dx+dy*dy)/dt));
    //print("3D motion: "+(Math.Sqrt(dx*dx+dy*dy+dz*dz)/dt));
    vars.x = current.x;
    vars.y = current.y;
    vars.z = current.z;
    vars.t = current.t;
  }
}