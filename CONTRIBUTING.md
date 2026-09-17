# Contributing to Moodist

Thanks for your interest in improving Moodist. The monorepo contains native macOS and iPhone apps sharing MoodistKit.

## Before You Start

- Open an issue before larger changes, behavior changes, UI rewrites, or changes that affect audio playback, persistence, releases, or bundled assets.
- Keep changes small and scoped to the issue or bug being addressed.
- Preserve macOS 15/26 compatibility and iPhone iOS 26+.
- Avoid unrelated formatting, file reorganization, or broad refactors in feature or bug-fix pull requests.

## Development Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/jsgrrchg/MoodistMac.git
   cd MoodistMac
   ```

2. Open the project in Xcode:

   ```bash
   open Moodist.xcodeproj
   ```

3. Use Xcode 26.2+ and select `MoodistMac` or `MoodistIOS`; install an iOS 26 simulator runtime for mobile tests.
4. Build and run with Xcode, or validate from the command line:

   ```bash
   xcodebuild -project Moodist.xcodeproj -scheme MoodistMac -configuration Debug build
   ```

Both apps use SwiftUI and the local MoodistKit package. AppKit and Sparkle belong only to macOS; UIKit, AVAudioSession and MediaPlayer adapters belong to iOS. Keep dependency changes intentional and explain them clearly in the pull request.

## Compatibility

Moodist supports macOS 15 and macOS 26. When changing SwiftUI, AppKit, audio, menu bar, windowing, update, or persistence behavior:

- Prefer APIs available on macOS 15 unless a newer API is guarded with availability checks.
- Test visual and interaction changes on both supported macOS generations when possible.
- Keep fallback behavior clear for older supported systems.
- Do not raise `MACOSX_DEPLOYMENT_TARGET` without prior discussion.

## Code Style

- Follow the existing Swift and SwiftUI structure in the repository.
- Keep views, stores, services, models, and helpers within their current ownership boundaries.
- Prefer readable, direct code over new abstractions unless the abstraction removes real duplication or complexity.
- Add code comments only when they clarify non-obvious behavior. Comments should be written in English.
- Keep user-facing strings localized in `en.lproj`, `es.lproj` and `pt-BR.lproj` under `Packages/MoodistKit/Sources/MoodistKit/Resources` when adding or changing UI text.

## UI and UX Changes

Moodist has a focused desktop interface and a native iPhone interface. UI changes should feel native, polished, and consistent with the existing interface.

- Respect the current layout, spacing, control style, and theme/accent behavior.
- Check light, dark, and automatic appearance when changing visual elements.
- Verify that text fits in compact windows, sheets, menus, and all three localized UIs.
- Preserve accessibility, keyboard shortcuts, and menu behavior unless the issue explicitly changes them.

## Audio, Data, and Assets

- Be careful with playback state, timers, favorites, recents, presets, and import/export behavior. We do not want to break sound or mix selections under any circumstance.
- Do not rename, remove, or replace bundled sounds without checking all references.
- New sound or visual assets are welcome, but **must have clear licensing that allows redistribution with this app**.
- Keep third-party asset credits and license notes accurate.

## Validation

For shared core or resource changes, validate both consumers:

```bash
swift test --package-path Packages/MoodistKit
python3 scripts/ios/catalog-inventory.py --check
python3 scripts/ios/check-localizations.py
python3 scripts/ios/validate-project.py
xcodebuild -project Moodist.xcodeproj -scheme MoodistMac -destination 'platform=macOS,arch=arm64' test CODE_SIGNING_ALLOWED=NO
destination="$(python3 scripts/ios/simulator-destination.py)"
xcodebuild -project Moodist.xcodeproj -scheme MoodistIOS -destination "$destination" test CODE_SIGNING_ALLOWED=NO
node --test scripts/release/test-release-tooling.mjs
python3 scripts/ios/test-release.py
```

Also manually verify the behavior you changed. For UI and playback changes, check the relevant app surface, such as the main window, menu bar menu, floating player, options, timers, favorites, recents, import/export, or update flow.

## Pull Requests

Please include:

- A concise summary of the change.
- The issue number, when applicable.
- The validation performed.
- Screenshots or screen recordings for visible UI changes.
- Notes about macOS 15 and macOS 26 compatibility when relevant.

Thank you for your contributions!

## Shared ownership and releases

Keep catalog IDs, UserDefaults keys and the JSON v1 format stable. Use an injected PreferencesRepository in domain tests; do not modify real user defaults. Update catalog/rights inventories when adding assets, with actual redistribution evidence. Shared code must not import AppKit, UIKit or Sparkle.

Use iOS 26 native controls and Liquid Glass for navigation/playback surfaces, respect Reduce Transparency and Dynamic Type, and avoid desktop-only settings on iPhone. Read [QA](docs/ios/QA.md) before claiming complete platform parity. Tests with a fake clock or simulator do not validate physical-device energy use or routes.

Mac releases retain `v*`; iOS uses `ios/v*` and its own [release guide](docs/ios/RELEASE.md). Never put signing material in the repository. The automated workflow has not been run remotely as part of initial implementation.
