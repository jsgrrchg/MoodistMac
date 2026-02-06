# Changelog

All notable changes to Moodist (macOS) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [BETA 5] – 2026-02-06

### Added
- **Sounds**: New sound category **Military** (Air Defense Alarm, Army Drill, Battlefield, City Bombing, Distant Battlefield, Futuristic Battle, Machine Gun, Military March, Soldiers Marching, Fighter Jet) with icon.
- **Sounds**: New sounds in existing categories: Nature (Rainforest, Rocks Falling, Sea Cave, Walking on Wood); Animals (Blackbird, Cat Meow, Ducks, Elephant, Lion, Macaws, Mandrill Baboon, Penguin, Peregrine Falcon, Pipit Bird, Wren Bird); Places (Children Playing, Chinese Kitchen, Flea Market, Trading Floor); Transport (Bike Ride, Dumper Truck, Fog Horn, Diesel Fork Lift); Things (Bells, Cash Register, Mouse Clicking, Printer, Wood Creak, Fetal Heart Beat, Heart Pulse Monitor); Noise (Men Snoring, Baby Crying). All with icons and localized labels (EN/ES).
- **Sounds**: “Collapse all” / “Expand all” button above the category list to collapse or expand all sound categories in one tap; label and icon switch dynamically depending on state (ContentView).
- **Mixes**: Same “Collapse all” / “Expand all” button above the mix categories list (ContentView).
- **Mixes**: 30 new mixes added across categories (Nature & Relaxation, Sea & Coast, Forest Fire & Night, Rain & Storm, Focus & Study, Travel & Motion, Sleep & Noise, Places & Ambience).
- **Mixes**: New mix category **Military** (14 mixes: Air Defense Watch, Barracks Drill Morning, Combat Engineering Yard, Distant Frontline Wind, Emergency Broadcast, Field Radio Post, Fighter Jet Flyover, Futuristic Ops Center, Marching Column, Night Patrol Steps, Range Practice Distance, Signal Intercept, Urban Blackout, War Room Briefing). Category appears last in the list. Localized title (EN/ES).

### Changed
- **Sounds**: Sounds within each category are now ordered alphabetically by label; category order is unchanged (SoundsData).
- **Mixes**: Mixes within each category are now ordered alphabetically by name; category order is unchanged (MixesData).
- **Options**: Options window size is fixed (510×650); resizing is disabled via `.windowResizability(.contentSize)` and a fixed content frame so the window always opens at the same size (MoodistApp).
- **Options**: Preference change notifications now use the shared `Notification.Name` extensions (`.menuBarPreferenceDidChange`, `.appearancePreferenceDidChange`, `.transparencyPreferenceDidChange`) instead of string literals (OptionsView).
- **Mixes**: `Mix.toPreset()` now passes `iconName` into the preset so converted mixes keep their icon (Mix.swift).
- **Updates**: Check-for-updates menu item uses a single ViewModel created in the app and passed into `CheckForUpdatesView`, so the “can check for updates” state is stable across view updates (MoodistApp, CheckForUpdatesView).
- **Search**: Toolbar search field resets the focus-request binding in a deferred run so it doesn’t trigger extra update cycles (ContentView, ToolbarSearchField).
- **Sidebar**: `recentMixes` and `favoriteMixes` use a local variable `byId` instead of shadowing the `presetsById` property, for clearer code (SidebarView).
- **Audio**: Failed sound loads (missing resource or `AVAudioPlayer` error) are logged to the console for easier debugging (AudioService).
- **Audio (memory)**: The player releases audio buffers (`AVAudioPlayer`) when a sound is deselected or when "Unselect all" / reset is triggered; only players for currently selected sounds are kept in memory. This optimizes memory usage without affecting application performance (AudioService, SoundStore).
- **Options**: Default accent color is now Graphite instead of Multicolor (system); new users and invalid preference values get Graphite (MoodistApp, OptionsView, AccentColorChoice).
- **Sidebar (drag and drop)**: Reordering of Favorite sounds and Favorite mixes now happens only when the user releases the drag (performDrop) instead of on every row crossing; a single animation runs on drop. An insertion line indicates the drop position while dragging. Favorite lists use VStack instead of LazyVStack for stable drop targets and smoother behavior (SidebarView).

### Fixed
- **Options (accent color)**: Changing the accent color in Options now updates the main window immediately; items no longer appear “stuck” until the app is restarted or the mouse is moved over them. Implemented by posting `.accentPreferenceDidChange` when the accent changes and refreshing the main content identity so SwiftUI re-evaluates accent-dependent views (MoodistApp, OptionsView).
- **Sidebar**: When scrolling the sidebar, content no longer invades the window traffic lights (close, minimize, maximize). A reserved top area (`safeAreaInset`) keeps hits from reaching the title bar, and a mask clips the scroll content so it is not drawn over the buttons (SidebarView).

### Removed
- **Options (Text size)**: The "Text size" preference and its picker have been removed from the Appearance section. The app now uses the system default type size; semantic fonts (`.body`, `.subheadline`, etc.) still scale with the system accessibility setting (ContentView, OptionsView, PersistenceService).
- **Main window**: Removed deprecated `UserDefaults.standard.synchronize()` after saving the window frame; persistence is now handled by the system.
---

## [BETA 4] – 2026-02-05

### Added
- (Nada aún.)

### Changed
- **Interface (Tahoe)**: Interface modifications with a specific target for macOS Tahoe.
- **Favorites**: Favorites are synced on import and fully cleared on reset (SoundStore.swift).
- **Playback state**: Avoid `isPlaying` true when nothing is selected on unselect and togglePlay (SoundStore.swift).
- **Mixes**: Sound cache per mix with key dependent on `soundIds` (MixCategoryView.swift).
- **Dead code removed**:  MoodistApp.swift, ContentView.swift, Color+Hex.swift.
- **Cleanup**: Removed `volumeBeforeMute` after removing toggleMute (SoundStore.swift).
- **Updates**: Improved automatic-update experience with a redesign of the update window, you can check it out with a special flag in the Options window. 
- **Save mix (modal)**: Icon selector replaced the dropdown with a visual grid of icon buttons (`LazyVGrid`): clearer selection state, tooltips per icon, and an "Icon: …" label below to confirm the choice. More scannable and direct; accessibility hint updated so it no longer refers to a "menu".
- **Main window**: Window dragging is disabled for the background content; the window can only be moved by dragging the top title bar. Implemented by disabling `isMovableByWindowBackground` (MoodistApp), a dedicated `TitlebarDragArea` in the top backdrop (ContentView), and simplified sidebar so it no longer participates in drag.

### Fixed
- **Floating player**: Mix title and volume icon in the bar now update correctly when switching between light and dark mode (no app restart required).
- **Floating player (dark mode)**: Mix title and volume icon are displayed in white for proper contrast on the bar.
- **Sounds / Mixes (hover)**: During scroll, only “hover true” is blocked; “hover false” is still applied so the hover state no longer gets stuck on rows (SoundRow, MixCategoryView).

### Removed
- **Dock icon**: Red badge on the app icon (mix name) is no longer shown; the dock tile badge is always cleared.
- **Menu bar icon**: Options entry removed from the status bar icon context menu.
- **Dock icon**: Options and Search entries removed from the dock icon context menu.

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

[Unreleased]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-5...HEAD
[BETA 5]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-4...Beta-5
[BETA 4]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-4
[Beta 3]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-3
[Beta 2]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-1...Beta-2
[Beta 1]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-1
