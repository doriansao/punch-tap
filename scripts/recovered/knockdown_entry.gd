extends RefCounted
## Bank 7 $83EB (player down) and $8404 (opponent down), including $8421/$8435.
## Called after contact damage reaches zero, before actor coordination.
static func apply(m: PackedInt32Array, opponent_down: bool) -> PackedInt32Array:
 m[0x301]|=1
 if opponent_down:
  m[0x4a]=0;m[0x4b]=0;m[0x4c]=0
  m[0x3e3]=1;m[0x3e0]=128
  m[5]=1;m[0x36]=1;m[0xbb]=0;m[0x3cb]=0
 else:
  m[0x320]=128;m[0x340]=128;m[0xbb]=128
  m[5]=2;m[0xbc]=1;m[0x3c5]=0
 return m
