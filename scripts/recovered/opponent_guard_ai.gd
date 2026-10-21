extends RefCounted
## $C291 guard response. Anticipatory poses are triggered by player target events.
var m:=PackedInt32Array()
func _init() -> void:m.resize(2048)
func _chance(threshold: int, mask: int) -> bool:
 if threshold==mask:return true
 var value:=m[0x18];var carry:=int(threshold>=mask)
 for bit in 3:
  var next_carry:=m[0x18]&1
  m[0x18]=(m[0x18]>>1)|(carry<<7);carry=next_carry
 return threshold>(value&mask)
func _set_guard() -> void:m[0x4ff]=(m[0xd2]>>3)|128
func step() -> void:
 if m[0x90]==0:return
 if m[0x90]==129:
  if not m[0xac]&128:m[0x4fe]=0;m[0xac]=0;m[0x4ff]|=128
 elif m[0x90]==1:
  if m[0x4fd]!=0:
   m[0x4fd]=(m[0x4fd]-1)&255
   if m[0x4fd]==128:m[0x4fd]=0
   if m[0x4fd]==0:_set_guard()
  elif m[0xac]>0 and m[0xac]<128:
   if m[0x4fe]!=0:
    m[0x4fe]-=1
    if m[0xd2]>>3 != m[0x4ff]&127:m[0x4fd]=m[0x5b8];m[0x4fe]=0
   elif m[0x50]&127==1 and m[0xd2]>>3 != m[0x4ff]&127:
    if m[0x5bc]&128:m[0x4fd]=m[0x5b8]
    else:m[0x4fe]=m[0x5bc];_set_guard()
 var trigger:=m[0x99]
 if trigger==0:return
 m[0x99]=0
 if m[0x4fd]!=0:
  if m[0x4fd]<128:m[0x4fd]=m[0x5ba] if m[0x4fd]>=m[0x5b9] else m[0x5bb]
  return
 if m[0x97]!=0 or m[0x4a]!=0:return
 var target:=m[0x74]
 if m[0x348]==0 and target&128:m[0x90]=131;return
 if m[0x3cb]==1 and target&128:return
 if m[0x3cb]==7 and target&128:m[0x90]=131;return
 if target&128:m[0x90]=137;return
 var body:=target&2
 var expected:=(body^2)>>1
 if trigger&128 and (trigger&127&m[0x58a])!=0 and _chance(m[0x58b],255):
  if m[0x58c]!=0:m[0x90]=m[0x58c];return
 var guaranteed:=not bool(m[0xac]&128) and (m[0x90]&127)==1 and (m[0x4ff]&127)==expected
 if body:
  if not guaranteed and not _chance(m[0x587],255):return
  if _chance(m[0x589]&127,127):m[0xab]=1
  m[0x90]=137+(target&3)
 else:
  if not guaranteed and not _chance(m[0x586],255):return
  if m[0x588]&128:
   if _chance(m[0x588]&127,127):m[0xab]=1
   m[0x90]=137+(target&3)
  else:
   if _chance(m[0x588],127):m[0xab]=128
   m[0x90]=131+(target&1)
