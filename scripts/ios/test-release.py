#!/usr/bin/env python3
import fnmatch
import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).with_name('release-metadata.py')
spec = importlib.util.spec_from_file_location('release_metadata', path)
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def settings(self):
        return [{'target': 'MoodistIOS', 'buildSettings': {
            'MARKETING_VERSION': '1.0', 'CURRENT_PROJECT_VERSION': '7',
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.josegurruchaga.MoodistIOS',
            'IPHONEOS_DEPLOYMENT_TARGET': '26.0'}}]

    def test_selects_app_not_last_package_or_mac_target(self):
        data = [{'target': 'MoodistMac', 'buildSettings': {}}] + self.settings() + [
            {'target': 'MoodistKit', 'buildSettings': {}}]
        self.assertEqual(release.metadata(data)['build'], '7')

    def test_rejects_ambiguous_or_missing_target(self):
        for data in [[], self.settings() * 2]:
            with self.assertRaises(ValueError): release.metadata(data)

    def test_minimum_and_build_are_checked(self):
        for key, value in [('IPHONEOS_DEPLOYMENT_TARGET', '27.0'), ('CURRENT_PROJECT_VERSION', '0')]:
            data = self.settings(); data[0]['buildSettings'][key] = value
            with self.assertRaises(ValueError): release.metadata(data)

    def test_tag_is_independent_of_mac_release(self):
        release.validate_tag('ios/v1.0', '1.0')
        for tag in ['v1.0', 'ios/v2.0', 'ios/v1.0\n', '--help']:
            with self.assertRaises(ValueError): release.validate_tag(tag, '1.0')
        mac = path.parents[2] / '.github/workflows/release-macos.yml'
        self.assertIn('- "v*"', mac.read_text())
        self.assertFalse(fnmatch.fnmatchcase('ios/v1.0', 'v*'))


if __name__ == '__main__': unittest.main()
