#!/usr/bin/env python3
"""CI-only signing/upload; never invoked by builds or pull-request validation."""
import base64
import json
import os
from pathlib import Path
import plistlib
import secrets
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def run(*args, **kwargs):
    return subprocess.run(list(args), check=True, **kwargs)


def main():
    if os.environ.get('GITHUB_ACTIONS') != 'true':
        raise SystemExit('Signing script is limited to the dedicated GitHub Actions release job')
    names = ['IOS_DISTRIBUTION_P12_BASE64', 'IOS_P12_PASSWORD', 'IOS_PROVISION_PROFILE_BASE64',
             'ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_PRIVATE_KEY_BASE64', 'IOS_TEAM_ID', 'ASC_APP_ID']
    if any(not os.environ.get(k) for k in names):
        raise SystemExit('Missing signing or App Store Connect configuration (see RELEASE.md)')
    run('python3', 'scripts/ios/check-asset-rights.py', '--release')
    meta = json.loads(subprocess.check_output(['python3', 'scripts/ios/release-metadata.py']))
    archive = ROOT / '.derived/MoodistIOS.xcarchive'
    with tempfile.TemporaryDirectory(prefix='moodist-signing-', dir=os.environ['RUNNER_TEMP']) as temp:
        folder = Path(temp)
        p12, profile, key = [folder / name for name in ['distribution.p12', 'profile.mobileprovision', 'AuthKey.p8']]
        for path, env in [(p12, names[0]), (profile, names[2]), (key, 'ASC_PRIVATE_KEY_BASE64')]:
            path.write_bytes(base64.b64decode(os.environ[env], validate=True)); path.chmod(0o600)
        profile_info = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', str(profile)]))
        team = os.environ['IOS_TEAM_ID']
        entitlement = profile_info['Entitlements']
        if (team not in profile_info['TeamIdentifier'] or
            entitlement.get('application-identifier') != team + '.' + meta['bundle_id'] or
            entitlement.get('get-task-allow', False) or 'ProvisionedDevices' in profile_info or
            profile_info.get('ProvisionsAllDevices', False)):
            raise SystemExit('Profile must be an App Store distribution profile for this team and bundle')
        profile_dir = Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles'
        profile_dir.mkdir(parents=True, exist_ok=True)
        installed = profile_dir / (profile_info['UUID'] + '.mobileprovision')
        previous_profile = installed.read_bytes() if installed.exists() else None
        keychain = folder / 'release.keychain-db'
        password = secrets.token_urlsafe(32)
        prior = subprocess.check_output(['security', 'list-keychains', '-d', 'user'], text=True)
        prior = [line.strip().strip('"') for line in prior.splitlines()]
        try:
            installed.write_bytes(profile.read_bytes())
            run('security', 'create-keychain', '-p', password, str(keychain))
            run('security', 'set-keychain-settings', '-lut', '7200', str(keychain))
            run('security', 'unlock-keychain', '-p', password, str(keychain))
            run('security', 'import', str(p12), '-k', str(keychain), '-P', os.environ['IOS_P12_PASSWORD'],
                '-T', '/usr/bin/codesign', '-T', '/usr/bin/security', stdout=subprocess.DEVNULL)
            run('security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s',
                '-k', password, str(keychain), stdout=subprocess.DEVNULL)
            run('security', 'list-keychains', '-d', 'user', '-s', str(keychain), *prior)
            run('xcodebuild', '-project', 'Moodist.xcodeproj', '-scheme', 'MoodistIOS', '-configuration', 'Release',
                '-destination', 'generic/platform=iOS', '-archivePath', str(archive), 'archive',
                'CODE_SIGN_STYLE=Manual', 'CODE_SIGN_IDENTITY=Apple Distribution', 'DEVELOPMENT_TEAM=' + team,
                'PROVISIONING_PROFILE_SPECIFIER=' + profile_info['UUID'])
            app = archive / 'Products/Applications/MoodistIOS.app'
            run('python3', 'scripts/ios/validate-built-app.py', str(app))
            run('codesign', '--verify', '--deep', '--strict', str(app))
            options = folder / 'ExportOptions.plist'
            options.write_bytes(plistlib.dumps({'method': 'app-store-connect', 'destination': 'upload',
                'teamID': team, 'signingStyle': 'manual', 'signingCertificate': 'Apple Distribution',
                'provisioningProfiles': {meta['bundle_id']: profile_info['UUID']},
                'manageAppVersionAndBuildNumber': False, 'uploadSymbols': True}))
            run('xcodebuild', '-exportArchive', '-archivePath', str(archive), '-exportPath', str(ROOT / '.derived/export'),
                '-exportOptionsPlist', str(options), '-authenticationKeyPath', str(key),
                '-authenticationKeyID', os.environ['ASC_KEY_ID'], '-authenticationKeyIssuerID', os.environ['ASC_ISSUER_ID'])
            run('ruby', 'scripts/ios/wait-for-processing.rb', str(key), os.environ['ASC_KEY_ID'],
                os.environ['ASC_ISSUER_ID'], os.environ['ASC_APP_ID'], meta['version'], meta['build'])
        finally:
            run('security', 'list-keychains', '-d', 'user', '-s', *prior)
            subprocess.run(['security', 'delete-keychain', str(keychain)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if previous_profile is None: installed.unlink(missing_ok=True)
            else: installed.write_bytes(previous_profile)


if __name__ == '__main__':
    os.chdir(ROOT)
    try:
        main()
    except subprocess.CalledProcessError as error:
        # A security command can contain a password. Never format its argv.
        raise SystemExit(f'Release command failed (exit {error.returncode}); inspect the preceding tool output') from None
