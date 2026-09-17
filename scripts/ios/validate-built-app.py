#!/usr/bin/env python3
import argparse, json, plistlib
from pathlib import Path
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('app',type=Path);args=parser.parse_args()
app=args.app
info=plistlib.loads((app/'Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='com.josegurruchaga.MoodistIOS'
assert info['MinimumOSVersion']=='26.0'
assert info['UIBackgroundModes']==['audio']
assert info['CFBundleIcons']['CFBundlePrimaryIcon']['CFBundleIconName']=='AppIcon'
assert not list(app.rglob('*Sparkle*'))
assert (app/'PrivacyInfo.xcprivacy').is_file()
# Debug testing can embed another copy in the test host/framework. Validate the
# app's canonical package bundle; Release archives must contain exactly one.
bundles=[p for p in app.glob('*.bundle') if (p/'sounds').is_dir()]
if not (app/'PlugIns').exists():
    assert len([p for p in app.rglob('*.bundle') if (p/'sounds').is_dir()]) == 1
assert len(bundles)==1,bundles
bundle=bundles[0]
for item in json.loads((root/'docs/ios/catalog-inventory.json').read_text())['sounds']:
    assert (bundle/'sounds'/item['category']/item['file']).is_file(),item['id']
for locale in ['en','es','pt-BR']:assert (bundle/f'{locale}.lproj/Localizable.strings').is_file()
assert (bundle/'PrivacyInfo.xcprivacy').is_file()
print('Validated built iOS app, icon, privacy manifests, 131 audio assets and three locales')
