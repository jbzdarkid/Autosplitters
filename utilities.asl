state("witness64_d3d11") {
  float x  : 0x5B5528;
  float y  : 0x5B552C;
  float z  : 0x5B5530;
  double t : 0x5A6C30;
  // globals = 0x5B28C0;
}

init {
  double oldx = 0.0;
  double oldy = 0.0;
  double oldz = 0.0;
  double oldt = 0.0;
  double INTERVAL = 1.0;
  vars.printSpeed = (Action<int>)((int dimFlags) => {
    if (current.t - oldt > INTERVAL) {
      double dx = current.x-oldx;
      double dy = current.y-oldy;
      double dz = current.z-oldz;
      double dt = current.t-oldt;
      double norm = 0.0;
      if ((dimFlags & 1) != 0) norm += dx*dx;
      if ((dimFlags & 2) != 0) norm += dy*dy;
      if ((dimFlags & 4) != 0) norm += dz*dz;
      print("Motion ("+dimFlags+"): "+Math.Sqrt(norm)/dt);
      oldx = current.x;
      oldy = current.y;
      oldz = current.z;
      oldt = current.t;
    }
  });
  
  var pointerData = new Dictionary<int, Tuple<DeepPointer, byte, byte, int>>();
  int STABILITY = 1;
  vars.offsetWatch = (Action<Func<int, DeepPointer>>)((Func<int, DeepPointer> getPointerAtOffset) => {
    string output = "";
    for (int offset=0; offset<0xFFF; offset++) {
      if (!pointerData.ContainsKey(offset)) {
        var pointer = getPointerAtOffset(offset);
        pointerData[offset] = new Tuple<DeepPointer, byte, byte, int>(
          pointer, // Reference pointer
          pointer.Deref<byte>(game), // Old value
          pointer.Deref<byte>(game), // Current value
          STABILITY // Stability
        );
        continue;
      }
      byte val = pointerData[offset].Item1.Deref<byte>(game);
      if (val != pointerData[offset].Item3) {
        pointerData[offset] = new Tuple<DeepPointer, byte, byte, int>(
          pointerData[offset].Item1,
          pointerData[offset].Item3,
          val,
          0
        );
      } else {
        pointerData[offset] = new Tuple<DeepPointer, byte, byte, int>(
          pointerData[offset].Item1,
          pointerData[offset].Item2,
          pointerData[offset].Item3,
          pointerData[offset].Item4 + 1
        );
      }
      if (pointerData[offset].Item4 == STABILITY) {
        output += "0x"+offset.ToString("X") + ": " + pointerData[offset].Item2 + " -> " + pointerData[offset].Item3 + " | ";
      }
    }
    if (output != "") print(output);
  });
}

update {
  // vars.printSpeed(7); // 3D Speed
  Func<int, DeepPointer> getPointerAtOffset = (offset) => {
    return new DeepPointer(0x5B28C0, 0x18, 0x00A64*8, offset);
  };
  vars.offsetWatch(getPointerAtOffset);
}