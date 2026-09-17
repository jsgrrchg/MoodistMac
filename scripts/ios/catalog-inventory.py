#!/usr/bin/env python3
"""Audit source catalog paths and produce a deterministic resource inventory."""
import argparse, json, re
from pathlib import Path
root = Path(__file__).resolve().parents[2]
shared = root / 'Packages/MoodistKit/Sources/MoodistKit'
data = shared / 'Catalog' if shared.exists() else root / 'Moodist/Data'
resources = shared / 'Resources/sounds' if (shared / 'Resources/sounds').exists() else root / 'Moodist/sounds'
sounds = [dict(zip(('id', 'label', 'file', 'category'), m)) for m in re.findall(r'Sound\(id: "([^"]+)", label: "([^"]+)", fileName: "([^"]+)", categoryFolder: "([^"]+)"', (data/'SoundsData.swift').read_text())]
mixes = [dict(id=m[0], sounds=re.findall(r'"([^"]+)"',m[1])) for m in re.findall(r'Mix\(id: "([^"]+)".*?soundIds: \[([^\]]*)\]', (data/'MixesData.swift').read_text())]
ids = {s['id'] for s in sounds}
assert len(ids) == len(sounds) == 131
assert len({m['id'] for m in mixes}) == len(mixes) == 123
for s in sounds:
    assert (resources/s['category']/s['file']).is_file(), s
for m in mixes:
    assert set(m['sounds']) <= ids, m
result = json.dumps({'soundCount':len(sounds),'mixCount':len(mixes),'sounds':sounds,'mixes':mixes},indent=2,ensure_ascii=False)+'\n'
parser=argparse.ArgumentParser()
parser.add_argument('--check',action='store_true')
args=parser.parse_args()
output=root/'docs/ios/catalog-inventory.json'
if args.check:
    assert output.read_text()==result, 'Catalog inventory needs regeneration'
else:
    output.write_text(result)
print(f'Validated {len(sounds)} sounds and {len(mixes)} mixes')
