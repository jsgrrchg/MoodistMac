# Contributing to Moodist

Thanks for your interest in improving Moodist. This project is a finished native macOS app, so it is best to keep things simple.

## Before You Start

- Open an issue before larger changes, behavior changes, UI rewrites, or changes that affect audio playback, persistence, releases, or bundled assets.
- Keep changes small and scoped to the issue or bug being addressed.
- Preserve compatibility with both macOS 15 and macOS 26.
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

3. Select the `MoodistMac` scheme.
4. Build and run with Xcode, or validate from the command line:

   ```bash
   xcodebuild -project Moodist.xcodeproj -scheme MoodistMac -configuration Debug build
   ```

The project uses SwiftUI, AppKit, AVFoundation, and Sparkle. Keep dependency changes intentional and explain them clearly in the pull request.

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
- Keep user-facing strings localized in both `en.lproj` and `es.lproj` when adding or changing UI text.

## UI and UX Changes

Moodist is a quiet, focused menu bar and desktop app. UI changes should feel native, polished, and consistent with the existing interface.

- Respect the current layout, spacing, control style, and theme/accent behavior.
- Check light, dark, and automatic appearance when changing visual elements.
- Verify that text fits in compact windows, sheets, menus, and localized Spanish UI.
- Preserve accessibility, keyboard shortcuts, and menu behavior unless the issue explicitly changes them.

## Audio, Data, and Assets

- Be careful with playback state, timers, favorites, recents, presets, and import/export behavior. We do not want to break sound or mix selections under any circumstance.
- Do not rename, remove, or replace bundled sounds without checking all references.
- New sound or visual assets are welcome, but **must have clear licensing that allows redistribution with this app**.
- Keep third-party asset credits and license notes accurate.

## Validation

Before opening a pull request, run at least:

```bash
xcodebuild -project Moodist.xcodeproj -scheme MoodistMac -configuration Debug build
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
