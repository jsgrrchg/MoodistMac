#!/usr/bin/env python3
import argparse, hashlib, json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--release',action='store_true');args=parser.parse_args()
assets=json.loads((root/'docs/ios/asset-rights.json').read_text())['assets']
expected={s['id'] for s in json.loads((root/'docs/ios/catalog-inventory.json').read_text())['sounds']}
assert len(assets)==len(expected) and {a['id'] for a in assets}==expected
pending=[]
for asset in assets:
    assert hashlib.sha256((root/asset['path']).read_bytes()).hexdigest()==asset['sha256'],asset['id']
    if asset['status']!='verified' or not all(asset[k] for k in ['sourceURL','author','license','redistributionEvidence']):pending.append(asset['id'])
print(f'{len(assets)} hashes verified; {len(pending)} assets still need redistribution evidence')
if args.release and pending:raise SystemExit('Release blocked: unresolved audio provenance')
