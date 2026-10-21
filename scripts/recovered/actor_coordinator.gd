extends RefCounted
## Active-fight actor coordination at $B549..$B5A7 and $B651..$B65F.
## Halt/ready flags, rather than a captured clip duration, release the actors.
static func step(m: PackedInt32Array) -> PackedInt32Array:
 if m[0x301]&128:
  m[0]=64
  return m
 if m[0x90]==0 or (m[0x343]!=0 and not m[0x343]&128):return m
 if m[5]!=0:
  if m[5]==2:
   if m[0x91]==131:m[0x90]=193;m[0x91]=129
  elif m[0x51]==131:m[0x50]=193;m[0x51]=129
  return m
 var flags:=m[0x91]&m[0x51]
 if flags&1:
  if flags==131:m[0x91]=0;m[0x90]=129;m[0x50]=(130-m[0xbc])&255
 elif m[0x91]==130 and m[0x51]==131:m[0x50]=(130-m[0xbc])&255
 return m
