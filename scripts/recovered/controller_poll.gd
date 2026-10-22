extends RefCounted
## Fixed bank $AFBD..$B020. Input is the stable serial-controller sample.
## $B021's hardware sample agreement is outside this semantic boundary.
static func step(m: PackedInt32Array, buttons: int) -> PackedInt32Array:
 m[0xd0]=buttons&255
 var masks: Array=[15,128,64,16,32]
 for i in masks.size():
  var address:=0xd2+i*2
  var value:=buttons&int(masks[i])
  if value!=m[address]:
   m[address]=value
   m[address+1]&=127
  elif value==0:
   m[address+1]&=126
  elif not (m[address+1]&1):
   m[address+1]|=129
 if (m[0x50]&127)==7:
  for address in [0xd5,0xd7,0xd9]:m[address]&=127
 return m
