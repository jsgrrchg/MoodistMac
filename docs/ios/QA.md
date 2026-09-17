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

## Final local evidence and limitations

- Package test run: 13 passing tests. Mac app integration: 1 passing test on the current host; this is not a macOS 15 runtime check.
- iOS unit/integration suite: 15 tests. UI suite: three flows also passed in two consecutive iterations after changing the mini-player to a safe-area inset.
- Release-tooling checks: original Mac Node suite and four iOS metadata/tag tests pass. Workflow YAML parses locally. No GitHub Actions run was triggered, because the branch was not pushed.
- A controlled temporary bundle with minimum OS 27.0 was rejected by the built-app validator; the fixture was removed. The real unsigned iOS archive passed the same validator with minimum 26.0, one resource bundle, all sounds/locales and no Sparkle.
- A newer iOS simulator runtime is not installed locally. CI's additional-runtime job records an explicit skip when unavailable; its iOS 26 job remains required.
- Xcode 27 beta stalled collecting simulator sysdiagnostics after the real-engine test emitted a Thread Performance Checker priority-inversion warning during system audio startup. Sampling the runner showed it waiting in `simctl diagnose`. The stalled invocations were stopped; the final run uses `-collect-test-diagnostics never`, retaining assertions, normal test logs and screenshots. This disables verbose sysdiagnose collection only. CI retains default diagnostics with stable Xcode 26.2. The startup warning needs device/Instruments review and is not considered resolved by disabling diagnostic collection.

Local working evidence is under the ignored `.PERSONAL/logs` and `.derived` directories. Tracked screenshots provide selected UI evidence; remote CI will retain xcresult artifacts when actually run.

Final combined iOS run completed with **TEST SUCCEEDED**: 15 unit/integration tests and three UI flows, with verbose diagnostic collection disabled as described above. Final accessibility screenshot review also led to a stacked volume label/value and bounded icon scaling at the largest text sizes.

Both application schemes also built successfully from a clean export of the C25 tracked source, using independent derived-data directories; the iOS bundle audit passed there. This verifies the committed project does not depend on ignored helper scripts or local resource copies.

## Player selection follow-up — 2026-09-17

The player opens expanded with a compact header and selected tracks before save/timer actions. The selection UI test opens a two-sound mix, checks both rows are visible immediately, pauses without losing selection, removes each track and verifies playback is disabled when empty. Localizations now validate 545 keys, including 39 iPhone keys.

Validation: all four iOS UI flows passed in `PlayerSelection.xcresult`; the selected-track screenshot was inspected.

## Sound volume popover — 2026-09-17

Long-pressing a sound opens an interactive volume popover anchored to its row. It preserves selection, updates that track through SoundStore.setVolume and offers VoiceOver an equivalent Volume action. Existing mix actions remain under the secondary menu. The five UI flows pass; the regression covers changing/reopening the volume, preserving selection for active and inactive sounds, and normal tap behavior. The screenshot was inspected. Localizations validate 546 keys (40 iPhone keys).

The strengthened regression also passed separately: the level changes from its initial value, the player reads the same changed level, global volume stays at 100%, and the other sound remains at 50%.
