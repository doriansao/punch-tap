from pathlib import Path
import itertools, json, hashlib

root = Path('research/evidence')
out = {}
for path in sorted(root.glob('*_ram.bin')):
    data = path.read_bytes()
    if not data:
        continue
    if len(data) % 2048:
        raise ValueError(str(path) + ' is incomplete')
    rows = {}
    for address, name in [(0x50, 'player_action'), (0x90, 'opponent_action'),
                          (0x391, 'player_hp'), (0x398, 'opponent_hp'),
                          (0x342, 'stars'), (0x347, 'star_hit_countdown'),
                          (0x323, 'hearts_tens'), (0x324, 'hearts_units'),
                          (0x06, 'round')]:
        offset, runs = 2295, []
        for value, group in itertools.groupby(data[address::2048]):
            count = len(list(group))
            runs.append(dict(value=value, first_frame=offset, frames=count))
            offset += count
        rows[name] = runs
    out[path.stem.removesuffix('_ram')] = dict(
        sha256=hashlib.sha256(data).hexdigest(), frames=len(data)//2048, runs=rows)
(root/'verified_summary.json').write_text(json.dumps(out, indent=2))
print('Summarized', len(out), 'complete captures')
