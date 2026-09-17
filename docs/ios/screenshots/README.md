# Simulator evidence

Captured from iPhone 17 Pro on iOS 26.2 with Xcode UI tests on 2026-09-16. Files are original simulator PNGs, not generated mockups.

- `catalog-ios26.png`: initial catalog baseline before the final mini-player inset change.
- `library-custom-mix.png`: a synthetic saved/favorited mix.
- `player-paused.png`: recalled mix, paused without losing selection.
- `settings.png`, `sleep-timer.png`: real navigation destinations.
- `large-text-dark-player.png`: accessibility-size text in dark appearance. A capture alone does not establish full VoiceOver usability.

The test source is `MoodistIOSUITests/MoodistFlowTests.swift`; CI attaches screenshots to xcresult files. These are QA evidence. Final App Store captures, other screen sizes, all localizations and physical contrast/accessibility review remain pending.
