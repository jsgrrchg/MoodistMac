# Validation record

Implementation evidence recorded on 2026-09-16. This is not an App Store approval or physical-device sign-off.

## Automated evidence

- Xcode 27.0 beta (27A5252f), iPhone 17 Pro simulator running **iOS 26.2**. CI pins Xcode 26.2 to check the minimum supported SDK.
- Shared package: 13 tests, including all 131 bundled audio files, catalog identifiers, preference round trips, malformed/future data, interruption intent and timers.
- iOS: 15 unit/integration tests, including real AVAudioEngine start/pause/rebuild in the simulator and audio-session policy through an injected driver.
- iOS UI: three flows cover selecting a sound, saving/favoriting/replaying a custom mix, pausing, settings/sleep navigation, and dark appearance with accessibility text size. UI tests use a separate preferences suite.
- Timer endurance test advances an injected clock through eight hours/96 rotations. **This is not eight hours of real playback or a battery measurement.**
- Mac integration verifies packaged resources from the app test host. Original release-tooling tests remain applicable.
- Catalog, localizations, project boundaries, resource bundle, privacy manifests and asset-rights inventory have script checks.

UI tests exposed unreliable presentation from the tab accessory; the app now owns a single observable presentation destination and places its glass mini-player in a safe-area inset above the tabs. The iOS 26 tab accessory repeatedly lost taps in tests, so it is not used for this critical control. Accessibility text sizes open the player at full height. Media-service reset constructs a fresh engine, and notification scheduling serializes cancelled requests to avoid deleting a replacement notification.

## Required manual sign-off before beta acceptance

| Environment / case | Status | Evidence required |
| --- | --- | --- |
| iPhone iOS 26: speaker, locked screen, background | Pending | Actual device playback, system controls and relaunch |
| 30 minutes and eight hours of audio | Pending | Device/OS, mix, battery start/end, thermal state, interruptions and Instruments trace |
| Calls/Siri, wired and Bluetooth disconnect, AirPlay | Pending | Route and interruption outcomes, no unintended restart |
| Other music apps with both audio policies | Pending | Correct coexistence and Now Playing ownership |
| VoiceOver, Reduce Motion/Transparency, contrast | Pending | Manual navigation, labels, gesture/keyboard access and readability |
| Small iPhone, rotation, all three languages | Pending | Screenshots and complete user flows, beyond static key checks |
| macOS 15 and 26 runtime regression | Pending | Existing data migration, Dock/menu bar/floating player, shortcuts and Sparkle |
| Export/import through Files and share destinations | Pending | Real file provider and two-platform transfer; codec is covered automatically |
| Signed release, install/update through TestFlight | Pending | Valid signature/profile, processed version/build and physical installation |

A registered physical iPhone was unavailable during this run. Simulator audio tests cannot replace route, background, endurance or energy checks. Store acceptance also requires the audio provenance recorded in ASSET_RIGHTS.md and an opaque, validated App Store icon. See RELEASE.md for distribution gates.
