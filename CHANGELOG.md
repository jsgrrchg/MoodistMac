# Changelog

All notable changes to Moodist (macOS) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Beta 3] – 2026-02-04

### Added
- **Floating player**: Clear (stop) button to unselect all sounds, placed to the left of the play button.
- **Timer**: Presets in minutes and hours; timer section in app menu and status bar menu reorganized with submenus.
- **Options**: Setting to choose how many recent sounds appear in the sidebar (10–15), matching the existing option for recent mixes.

### Changed
- **Menus**: Play shortcut in the menu bar icon menu and Dock menu is now ⌘R, matching the global Playback → Play shortcut.
- **Sounds**: "Currently playing" panel alignment now matches the width of the categories and sound rows below.
- **Sounds**: "Currently playing" title uses the same font size as category names (headline/title2, semibold).
- **Sounds**: "Save mix" and "Clear" in the Currently playing header modernized with `Label` + icons, subtle pill style, and responsive layout (icon-only on narrow width).
- **Sounds**: New `HeaderActionButtonStyle` for those buttons with hover/pressed states and visual hierarchy (accent for Save mix, secondary for Clear).
- **Sounds / Mixes (rows)**: Removed nested buttons in `SoundRow` and `MixRowView`; rows now use `onTapGesture` and the favorite button works without conflict. Same visual style (subtle background on hover/selection).
- **Sounds (timer)**: Timer moved out of the header and placed below the title, before the active sounds list, so it sits in context between the two. Added a subtle cancel button in the same row. Styling is more ambient: discreet typography, soft background, and a light capsule-style button that doesn’t compete with the main controls.
- **Floating player**: Tighter spacing between transport controls (shuffle, stop, play, forward).
- **Floating player**: Mix name scrolls horizontally (marquee) when it doesn’t fit.
- **Floating player**: Volume zone has an opaque background so the scrolling title doesn’t show through.
- **Floating player**: Removed the cover/mix icon from the bar for a simpler layout.
- **Sounds / Mixes**: Consistent fast crossfade animation when switching sections Sounds&Mixes
- **Sidebar**: Sidebar is now always visible; the hide/show toggle was removed from the toolbar and from the compact toolbar menu.
- **Search**: Native focus ring re-enabled on the search field so it’s clear when the field is active.
- **Search**: Magnifying glass icon restored on the search field for a clear “this is search” affordance.
- **Floating player (marquee)**: On macOS, marquee uses Core Animation (`CATextLayer` + `CABasicAnimation`) via `NSViewRepresentable` to avoid per-frame SwiftUI re-renders; SwiftUI fallback uses `TimelineView(.periodic)` at 0.06s (≈16 fps) to reduce invalidations.
- **Floating player**: Player container uses `contentShape` and `allowsHitTesting(true)` so the background scroll no longer steals clicks.
- **Performance**: Optimizations to reduce memory consumption and improve responsiveness.
- **Sidebar**: `recentMixes` and `favoriteMixes` now use a preset-by-id dictionary for O(1) lookup.

### Fixed
- **Playback**: `unselectAll()` now stops playback (`isPlaying = false`) and no longer resets volumes to 0.5.
- Sidebar: resizing no longer drags the window and the handle responds correctly.
- **Main window**: The top bar (toolbar area) now blocks clicks so they no longer pass through to the content below; that area is used only for dragging the window.

### Removed
- **Localization**: Unused `sidebarHide` and `sidebarShow` from L10n and `sidebar_hide` / `sidebar_show` from en and es `Localizable.strings` (sidebar is always visible now).
- **Code**: Removed unused code: `LanguageManager`, `CardBackgroundView`, `SidebarRowButtonStyle`, `buildDockMenu`, `menuToggleMute`, and unused constants/variables in `FloatingPlayerPanelView`.

---

## [Beta 2] – 2025-02-04

### Added
- **Updates**
  - Sparkle integration: automatic update checking
  - "Check for Updates…" menu item in the app menu (after About)
  - "Updates" section in Options with button to check manually
  - Appcast and EdDSA signature configured in `Info.plist` for secure updates
- **Main window**
  - Main window position and size are remembered between sessions
  - Closing with the red button hides the window; clicking the Dock icon shows it again

### Changed
- **Mixes**: Existing mixes were optimized
- **Performance**: General app performance improvements

### Fixed
- (Nothing notable.)

### Removed
- **Mixes**: Some mixes were removed

### Requirements
- macOS 15.0 (Sequoia) or later
- Swift 5.0, SwiftUI, Sparkle (updates)

---

## [Beta 1] – 2025-02-03

### Added
- **Sounds and mixes**
  - 89 sounds in 9 categories: Nature, Rain, Animals, Urban, Places, Transport, Things, Noise, and Binaural
  - 81 curated mixes in 10 themed categories
  - Custom mixes and presets; save and recall combinations
  - Favorites for sounds and mixes; quick access from sidebar and menu
  - Recent mixes in sidebar (configurable: 10–15 items)
- **Playback and control**
  - Global and per-sound volume
  - Sleep timer with presets and custom duration; notification when time is up
  - Optional “Next” media key to load a random mix
- **Interface**
  - Optional menu bar icon with quick access to playback, timer, sounds, and mixes
  - Floating player window (stays on top)
  - Search sounds by name (⌘F)
- **Appearance**
  - Theme: light, dark, or automatic
  - Text size: small, medium, large, extra large
  - Accent color: Multicolor or 9 fixed colors
  - Option to disable transparencies and frosted glass
- **Data**
  - Export/import preferences (custom mixes, favorites) as JSON
  - Reset selection and favorites; restore all to defaults
- **Accessibility and language**
  - Localization: English and Spanish (plus system language)
  - Keyboard shortcuts: Play/Pause (⌘R), Shuffle (⌘S), Next mix (⌘N), Unselect all (⌘U), Search (⌘F), Options (⌘,)

### Requirements
- macOS 15.0 (Sequoia) or later
- Swift 5.0, SwiftUI, no external dependencies

---

[Unreleased]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-3...HEAD
[Beta 3]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-3
[Beta 2]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-1...Beta-2
[Beta 1]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-1
