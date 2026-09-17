# Independent iOS release

Current app: `MoodistIOS`, bundle `com.josegurruchaga.MoodistIOS`, version **1.0.0**, build **1**, minimum iOS **26.0**, iPhone only. Mac versioning, Sparkle, `CHANGELOG.md`, `appcast.xml` and `v*` tags remain independent.

## Local unsigned rehearsal

Use stable Xcode 26.2+ with the iOS 26 simulator runtime. The local implementation was additionally built with Xcode 27 beta, which is not a claim of distribution eligibility.

```sh
python3 scripts/ios/release-metadata.py
python3 scripts/ios/test-release.py
xcodebuild -project Moodist.xcodeproj -scheme MoodistIOS -configuration Release -destination 'generic/platform=iOS' -archivePath .derived/MoodistIOS.xcarchive archive CODE_SIGNING_ALLOWED=NO
python3 scripts/ios/validate-built-app.py .derived/MoodistIOS.xcarchive/Products/Applications/MoodistIOS.app
```

The unsigned Release archive succeeded locally. Its minimum OS, resource bundle, 131 sound files, three locales, icon entry and privacy manifests passed validation. An unsigned archive cannot be installed through TestFlight and does not validate a distribution certificate.

## Gates before uploading

1. Complete the physical-device and desktop regression matrix in [QA.md](QA.md), recording device/OS and evidence. Eight hours with a fake clock is insufficient for endurance acceptance.
2. Resolve every entry in [asset-rights.json](asset-rights.json); `python3 scripts/ios/check-asset-rights.py --release` deliberately rejects the current 131 unverified entries. Do not mark evidence verified without actual redistribution rights.
3. Validate the App Store icon (the inherited source currently has an alpha channel), dark/tinted appearance, final screenshots, support and hosted privacy URLs, store metadata and review notes in APP_STORE.md.
4. Create the App Store Connect app for the exact bundle ID and complete agreements, access, export-compliance and beta-review information as applicable.
5. Increase the iOS build number for each upload; update only iOS target Debug/Release settings and `docs/ios/CHANGELOG.md`. The script disables Apple's automatic build-number rewriting so uploaded identity remains explicit.

## GitHub configuration

Create the `ios-release` environment. Configure secrets outside the repository:

| Secret | Value |
| --- | --- |
| `IOS_DISTRIBUTION_P12_BASE64` | Base64 Apple Distribution certificate plus private key, exported as P12 |
| `IOS_P12_PASSWORD` | Password of that P12 |
| `IOS_PROVISION_PROFILE_BASE64` | Base64 App Store distribution profile for this bundle/team |
| `ASC_KEY_ID` / `ASC_ISSUER_ID` | App Store Connect API key identifiers |
| `ASC_PRIVATE_KEY_BASE64` | Base64 P8 private key with access to this app |

Environment variables: `IOS_TEAM_ID` (Apple team), `ASC_APP_ID` (numeric App Store Connect app ID), and `IOS_RELEASE_READY=true` **only after the above evidence is complete**. This variable records release readiness; it does not substitute for the asset audit, tests or Apple validation.

The workflow reads credentials only in its signing step, installs a temporary keychain/profile, restores the prior search list/profile and removes temporary credentials even on command failure. Logs never format command arguments on signing errors. No credentials have been configured or consumed during implementation.

## Trigger and expected result

The `Release iOS` workflow accepts an existing `ios/vX.Y.Z` tag. A manual run defaults to **unsigned rehearsal** (`upload=false`); a push of an iOS tag requests upload. Both validate tag/version and require the tagged commit to belong to `origin/main`. No tag was created or pushed by this implementation.

Mac's automatic trigger remains `v*`, which does not match `ios/v1.0.0`; release-tooling tests cover this separation. iOS artifacts have their own names and do not update the Mac appcast.

On an authorized release, the workflow tests iOS, validates asset rights, archives with manual distribution signing, verifies the signature and resources, and uploads using `xcodebuild -exportArchive`. It polls Apple's API for the exact app/marketing version/build and fails on `FAILED`/`INVALID` or a 30-minute processing timeout. A timeout does not mean upload failed: inspect App Store Connect before retrying or changing the build number. API errors are reported without dumping tokens or response bodies.

A `VALID` processed build is not yet acceptance into a beta group or App Store approval. Assign testers, verify the displayed version/build, install/update on an iPhone, record feedback and finish beta review as needed. Publishing to the App Store is a separate later action.

## References

- [Apple: upload builds and processing](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds).
- [Apple: TestFlight distribution](https://help.apple.com/xcode/mac/current/en.lproj/dev2539d985f.html).
- [Apple: list builds](https://developer.apple.com/documentation/appstoreconnectapi/get-v1-builds).
- Export keys were checked against local `xcodebuild -help` (`app-store-connect`, manual signing, destination upload, manageAppVersionAndBuildNumber).
- [GitHub macOS 26 runner tools](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md). CI pins Xcode 26.2; newer installed runtimes provide additional coverage only.
