#!/usr/bin/env python3
import json, plistlib, subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[2]
project=json.loads(subprocess.check_output(['plutil','-convert','json','-o','-',str(root/'Moodist.xcodeproj/project.pbxproj')]))
objects=project['objects']
for name,key,minimum in [('MoodistMac','MACOSX_DEPLOYMENT_TARGET','15.0'),('MoodistIOS','IPHONEOS_DEPLOYMENT_TARGET','26.0')]:
    target=next(v for v in objects.values() if v.get('isa')=='PBXNativeTarget' and v.get('name')==name)
    for ident in objects[target['buildConfigurationList']]['buildConfigurations']:
        cfg=objects[ident]
        assert cfg['buildSettings'][key]==minimum,(name,cfg['name'],key)
        if name=='MoodistIOS':
            assert cfg['buildSettings']['TARGETED_DEVICE_FAMILY']=='1'
            assert cfg['buildSettings']['PRODUCT_BUNDLE_IDENTIFIER']=='com.josegurruchaga.MoodistIOS'
        elif cfg['name']=='Release':
            assert cfg['buildSettings']['ONLY_ACTIVE_ARCH']=='NO'
    dependencies=[objects[p]['productName'] for p in target.get('packageProductDependencies',[])]
    assert 'MoodistKit' in dependencies
    assert ('Sparkle' in dependencies)==(name=='MoodistMac')
for p in (root/'Packages/MoodistKit/Sources').rglob('*.swift'):
    assert not any('import '+framework in p.read_text() for framework in ['AppKit','UIKit','Sparkle']),p
info=plistlib.loads((root/'MoodistIOS/Resources/Info.plist').read_bytes())
assert info['UIBackgroundModes']==['audio']
assert not info.get('UIDesignRequiresCompatibility',False)
print('Validated platform targets, shared module boundaries, background audio and native design')
