# Accessibility and iOS design

The iPhone interface uses an inset mini-player with native Liquid Glass, native glass controls and system navigation surfaces. Custom playback controls switch to a bordered style when Reduce Transparency or the in-app transparency preference requests it. No custom motion is required to access actions.

Implemented: semantic selection/favorite values, labeled volume sliders, accessible reorder actions, 44-point row actions, Dynamic Type layouts, scrollable forms, localized errors and keyboard shortcuts (Command-R/S/N/U/comma). Search uses the system searchable control.

Verified locally: iOS 26.2 simulator launches and renders the sound catalog, tab bar and persistent player; see `screenshots/catalog-ios26.png`. Additional UI-test evidence is recorded in QA.md as those checks run.

Still requires a person/device: full VoiceOver navigation, hardware keyboard, real display contrast, calls/Siri and headphone controls. A screenshot is not proof of those behaviors.
