#!/usr/bin/env python3
import argparse, json, re, subprocess
parser=argparse.ArgumentParser()
parser.add_argument('--newer-than', help='Optional additional coverage; exit 3 if unavailable')
args=parser.parse_args()
state=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','--json']))
candidates=[]
for runtime,devices in state['devices'].items():
    match=re.search(r'\.iOS-(\d+)-(\d+)',runtime)
    if not match:continue
    version=tuple(map(int,match.groups()))
    eligible=version>tuple(map(int,args.newer_than.split('.'))) if args.newer_than else version[0]==26
    if eligible:
        for device in devices:
            if 'iPhone' in device['name']:candidates.append((version,device['udid']))
if candidates:
    print('platform=iOS Simulator,id='+sorted(candidates)[0][1]);raise SystemExit(0)
if args.newer_than:raise SystemExit(3)
raise SystemExit('Install an iOS 26 simulator runtime; a later OS does not validate the minimum target.')
