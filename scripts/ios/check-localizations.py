#!/usr/bin/env python3
"""Verify actual string keys and format placeholders across all supported locales."""
from pathlib import Path
import json, re, subprocess
root=Path(__file__).resolve().parents[2]
resources=root/'Packages/MoodistKit/Sources/MoodistKit/Resources'
tables={locale:json.loads(subprocess.check_output(['plutil','-convert','json','-o','-',str(resources/f'{locale}.lproj/Localizable.strings')])) for locale in ['en','es','pt-BR']}
required=set()
for p in (root/'MoodistIOS').rglob('*.swift'):
    required.update('ios_'+k for k in re.findall(r'T\("([^"\n]+)",',p.read_text()))
for locale,table in tables.items():
    assert required <= table.keys(), (locale,sorted(required-table.keys()))
    assert tables['en'].keys() <= table.keys(),(locale, sorted(tables['en'].keys()-table.keys()))
    for key in tables['en']:
        pattern=r'%(?:\d+\$)?(?:@|d|ld|lld|f|s|u)'
        assert sorted(re.findall(pattern,tables['en'][key]))==sorted(re.findall(pattern,table[key])),(locale,key)
print(f'Validated {len(tables["en"])} keys including {len(required)} iPhone keys in en, es and pt-BR')
