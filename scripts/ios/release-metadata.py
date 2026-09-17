#!/usr/bin/env python3
"""Read only the iPhone app target, independently of macOS/package settings."""
import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def metadata(settings):
    matches = [s['buildSettings'] for s in settings if s.get('target') == 'MoodistIOS']
    if len(matches) != 1:
        raise ValueError('Expected exactly one MoodistIOS target')
    s = matches[0]
    result = {key: s[value] for key, value in {
        'version': 'MARKETING_VERSION', 'build': 'CURRENT_PROJECT_VERSION',
        'bundle_id': 'PRODUCT_BUNDLE_IDENTIFIER', 'minimum_os': 'IPHONEOS_DEPLOYMENT_TARGET'
    }.items()}
    if not re.fullmatch(r'\d+\.\d+(?:\.\d+)?', result['version']):
        raise ValueError('Invalid iOS marketing version')
    if not re.fullmatch(r'[1-9]\d*', result['build']):
        raise ValueError('iOS build must be a positive integer')
    if result['minimum_os'] != '26.0' or result['bundle_id'] != 'com.josegurruchaga.MoodistIOS':
        raise ValueError('Unexpected iOS minimum OS or bundle identifier')
    return result


def validate_tag(tag, version):
    if not re.fullmatch(r'ios/v\d+\.\d+(?:\.\d+)?', tag) or tag != 'ios/v' + version:
        raise ValueError('Tag must be ios/v<MARKETING_VERSION> and match the iOS target')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--settings', type=Path)
    parser.add_argument('--tag')
    args = parser.parse_args()
    raw = args.settings.read_bytes() if args.settings else subprocess.check_output([
        'xcodebuild', '-project', str(ROOT / 'Moodist.xcodeproj'), '-scheme', 'MoodistIOS',
        '-configuration', 'Release', '-destination', 'generic/platform=iOS', '-showBuildSettings', '-json'
    ])
    result = metadata(json.loads(raw))
    if args.tag:
        validate_tag(args.tag, result['version'])
    print(json.dumps(result, indent=2))
