# Moodist monorepo development

The iPhone app supports iOS 26+, sharing the original catalog and domain with Mac. The Mac target remains macOS 15+. The package uses Swift tools 6 with Swift 5 language mode, matching the existing code during extraction.

## Build from a clean checkout

Requirements: a Mac supported by Xcode 26.2+, Xcode command-line tools selected, Swift package access for Mac's Sparkle dependency, and an iOS 26 simulator runtime installed. Open `Moodist.xcodeproj`; both schemes are shared. No Ruby project-generation step is needed.

```sh
xcodebuild -version
xcodebuild -list -project Moodist.xcodeproj
swift test --package-path Packages/MoodistKit
xcodebuild -project Moodist.xcodeproj -scheme MoodistMac -configuration Debug -destination 'platform=macOS,arch=arm64' build CODE_SIGNING_ALLOWED=NO
xcodebuild -project Moodist.xcodeproj -scheme MoodistIOS -configuration Debug -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
destination="$(python3 scripts/ios/simulator-destination.py)"
xcodebuild -project Moodist.xcodeproj -scheme MoodistIOS -destination "$destination" -resultBundlePath .derived/IOSTests.xcresult test CODE_SIGNING_ALLOWED=NO
```

Use a fresh result-bundle path on each run. If the Xcode 27 beta simulator diagnostic collector stalls after test completion, see QA.md; the local workaround is `-collect-test-diagnostics never`, not disabling tests. On Intel Mac, use `arch=x86_64` for the Mac destination. Physical iPhone installation requires selecting your development team and provisioning the bundle ID. The unsigned simulator build requires no signing credentials. Debug builds use the host Mac architecture; Mac Release remains universal.

## Structure and contracts

- `Packages/MoodistKit`: catalog, models, audio engine, store, timers, JSON codec and injected preferences repository. `MoodistResources.bundle` is the only resource resolver.
- `Moodist`: macOS presentation and platform adapters, including native file panels, windows, menus, notifications and Sparkle.
- `MoodistIOS`: native SwiftUI screens and lifecycle, audio session, Now Playing, system commands, notification and file-provider adapters.
- The same 131 audio files and 123 curated mixes serve both apps. JSON version 1 and original Mac defaults keys remain stable. App sandboxes have independent local data; export/import transfers supported preferences. There is no cloud synchronization.

CI validates both apps for all PRs and main changes, so shared-package changes cannot bypass a consumer. The minimum runtime job pins Xcode 26.2; another job tests a newer installed runtime when available and explicitly reports a skip otherwise. Signing belongs only to the independent release workflow.

## Guides

- [Mobile usage and background behavior](USAGE.md)
- [Feature parity and evidence](PARITY.md)
- [QA results and remaining physical checks](QA.md)
- [Accessibility and design](ACCESSIBILITY.md)
- [Asset distribution evidence](ASSET_RIGHTS.md)
- [iOS release workflow](RELEASE.md)
- [Store metadata draft](APP_STORE.md)
- [Privacy text](PRIVACY.md)

## Implementation status

C01–C26 have implementation commits, with validation limits explicitly recorded. This is not a declaration that every manual acceptance criterion is complete. Local automated tests and unsigned archives can be reproduced; physical playback/endurance, Mac 15 runtime regression, complete accessibility review, license provenance, hosted store URLs and signed TestFlight delivery remain open. No push or publication was performed.
