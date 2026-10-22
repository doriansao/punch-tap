extends RefCounted
## Animation-visible handshake only, from bank 7 $8A4B..$8A8B.
## Original HUD graphics bytecode is not rendered. Scripts wait on $40 == 3
## until the 16-frame boundary changes it to 4 before signalling bout finish.
static func step(m: PackedInt32Array) -> PackedInt32Array:
 if m[0x40]&128:
  if m[0x1e]&15:return m
  m[0x40]&=127
 if m[0x40]==0 or m[0x46]!=0:return m
 if m[0x40]==3 and (m[0x1e]&15)==0:m[0x40]=4
 return m
