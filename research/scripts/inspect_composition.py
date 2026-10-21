from pathlib import Path
import collections
r=Path('research/evidence/animation');c=collections.Counter();m=collections.defaultdict(set)
for p in r.glob('*_compositor.bin'):
 b=p.read_bytes()
 for off in range(0,len(b)//4100*4100,4100):
  a=b[off+4:off+2052];z=b[off+2052:off+4100]
  if a[0xa0]:c[(a[0xa0],a[0xa1],a[0xa2])]+=1;m[a[0xa1]].add((a[0xb2],a[0xb3],a[0x20c],a[0x20f]))
print(c)
