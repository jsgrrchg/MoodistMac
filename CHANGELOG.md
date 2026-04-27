# Changelog

All notable changes to Moodist (macOS) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] – 2026-04-27

### Fixed

- **Menu bar icon**: Fixed an issue where the menu bar icon could appear invisible by removing the manual translucency adjustment.

## [1.0.4] – 2026-03-17

### Added

- Smooth crossfade (~1.5s) when switching mixes or presets: outgoing sounds fade out, incoming sounds fade in, and sounds common to both presets transition volume without reloading.
- Pomodoro auto-mix: automatically switches to a random mix at a chosen interval (5m–1h), with a live countdown in the button.

### Changed

- **Liquid Glass (macOS 26)**: Applied native Liquid Glass material to panels and UI elements when running on macOS 26, maintaining the classic appearance on macOS 15.
- **Search bar (main window)**: Harmonized the search bar visual style in the main window for a more cohesive look.

### Fixed

- **Update window**: Aligned the app icon position in the update window for a more polished layout.

## [1.0.3] – 2026-03-01

### Added
- **Sounds/Mixes (gesture navigation)**: Added horizontal two-finger swipe support (trackpad and Magic Mouse) to switch between `Sounds` and `Mixes`, with tuned sensitivity to reduce accidental section changes.

### Changed
- **App entrypoint architecture**: Refactored the oversized `MoodistApp.swift` into focused app modules and coordinators. `MoodistApp` now acts as composition root, while app lifecycle and platform responsibilities were split into `MacOSAppDelegate`, `AppWindowCoordinator`, `AppMenuBarCoordinator`, `AppDockCoordinator`, `AppTimerCoordinator`, `MoodistCommands`, and Sparkle integration helpers.
- **SoundStore architecture**: Refactored `SoundStore.swift` into a facade plus domain-focused extensions to reduce complexity and improve maintainability. Responsibilities are now separated into `SoundStore+Playback`, `SoundStore+Timer`, `SoundStore+Presets`, `SoundStore+RecentsFavorites`, and `SoundStore+Persistence`.
- **Project structure**: Added a dedicated `App/` folder (with `Coordinators/`) and registered new split files in the Xcode project target to keep concerns grouped by domain.
- **ContentView architecture**: Refactored `ContentView.swift` to reduce local complexity and move responsibilities into reusable view modules. Scroll restoration wiring for Sounds/Mixes now goes through a shared `ContentScrollPanelView`, toolbar width/offset/search metrics were extracted into `ContentToolbarMetrics`, sidebar resize UI/gesture plumbing was extracted into `SidebarResizeHandleView`, and `HeaderActionButtonStyle` was centralized outside `ContentView` for reuse.

### Fixed
- **Timer (custom window start action)**: Fixed an issue where pressing `Start` could launch a 15-minute timer if a picker column (`h:min:s`) was still being edited. The Start flow now commits the active field before reading the duration, so the selected time is always applied correctly.
- **Intel compatibility (project configuration)**: Restored Intel Mac support after an unintended Xcode project configuration error had temporarily removed/affected it.
- **Command menu (custom mixes visibility)**: Fixed the `Mixes` app command menu so user-created custom mixes are listed correctly, including in the `Favorites` submenu.
- **Custom mix deletion (state cleanup)**: Fixed stale references after deleting a custom mix. Deletion now also removes related entries from recent/favorite mix lists and clears current editing/now-playing metadata when applicable.
- **Menu bar timer ticker lifecycle**: Fixed a menu-bar edge case where the 1-second timer updater could remain active after menu close/rebuild cycles. Timer menu updates are now stopped and detached reliably when the menu closes or the status item is hidden.
- **Preferences import (data sanitization)**: Fixed import robustness by sanitizing imported custom mixes and favorite IDs (deduplicating entries, filtering invalid IDs, and clamping imported volume values to valid bounds).
- **Updates (release notes rendering)**: Fixed Sparkle appcast release-note links to use versioned HTML notes, so the custom update window shows in-app release notes content instead of loading the generic GitHub Releases page.

---

## [1.0.2] – 2026-03_01

### Added
- None.

### Changed
- **Timer (UI redesign)**: Replaced the plain minutes text field with a drum-style `h : min : s` picker inspired by the macOS Clock app. Each column displays a large monospaced number; clicking any column activates an inline text field for manual input (digits only, clamped to valid range on confirm). Quick presets below remain unchanged.
- **Save mix (UI redesign)**: Completely redesigned the Save Mix sheet for better usability and visual clarity. Key improvements: centered preview icon header with subtle accent glow (replaces heavy header card), streamlined layout with fewer visual layers (single unified background instead of 3 separate cards), clean name input field without wrapper, removal of redundant "Sparkles" badge in the icon section and footer, narrower width (420px vs 460px) for a more compact feel, non-selected icons now display cleanly without background (only selected icons have accent background/border), smooth animations for icon preview changes and input focus states. The overall design maintains design system consistency while significantly reducing visual noise and improving the form hierarchy.
- **Sounds/Mixes transition internals**: Kept both section scroll views mounted and applied the section switch effect with slide+fade (`offset` + `opacity`) instead of mount/unmount transitions.
- **Sounds/Mixes transition feel**: Updated the section switch animation curve to a faster spring with a clearer bounce (`interpolatingSpring`) so tab changes feel snappier and more tactile.
- **Codebase cleanup**: Removed unused/dead code across models, services, theme tokens, localization entries, and UI helpers to keep the project leaner and easier to maintain.

### Fixed
- **Sounds/Mixes scroll restoration**: Fixed a regression where switching between sections reset the previous panel to the top. The app now preserves each section scroll position when moving from Sounds to Mixes and back. This bug was introduced accidentally in the previous release.
- **Sidebar drag & drop**: Improved reorder behavior in the Favorites and Favorite Mixes sections. Items now animate smoothly to their new position using a spring curve, an insertion line indicator appears at the drop target while dragging, and window controls no longer flicker during drag interactions.

---

## [1.0.1] – 2026-02-23

### Added
- **Save mix (icon library)**: Redesigned the icon picker as a navigable SF Symbols browser with category tabs and a searchable grid, allowing broader icon discovery while keeping the existing visual language.
- **Save mix (custom icon)**: Added a custom palm tree SVG icon (`PalmTreeSolid`) as a selectable option in the **Places** category, positioned as the first icon.
- **Custom mixes (edit action)**: Added an `Edit mix…` option in the context menu for saved custom mixes, opening the Save Mix sheet in edit mode to update name and icon.

### Changed
- **Timer**: The custom timer panel was converted into a standalone window, so it can be opened and used while the main app window is hidden (including access from Dock menu, menu bar menu, and app command menus).
- **Timer (main UI)**: Replaced the inline timer status row in `Currently Playing` with a header action button that opens the timer window; when active, the button now shows a live countdown and includes a quick `x` cancel control.
- **Timer window (positioning & sizing)**: The custom timer window now opens centered over the Moodist main window (instead of an arbitrary screen position), and its layout/size was tightened to a narrower footprint.
- **Save mix (layout harmony)**: Moved the category buttons directly below the `Search SF Symbols` field and harmonized spacing, hierarchy, and control styling across the whole sheet.
- **Save mix (visual redesign)**: Reimagined the Save Mix sheet with a stronger visual hierarchy (header preview, card-based sections, chip categories, larger icon grid, and clearer footer actions) while preserving the existing save flow.
- **Custom mixes spacing**: Matched the empty-state padding for the `Custom Mixes` placeholder to the `Currently playing` section so both panes align vertically.
- **Sounds/Mixes transition**: Replaced the fade swap with a directional slide+fade transition, so switching tabs feels like moving between stacked panels.
- **Mix icon rendering**: Introduced centralized `MixIcon` / `MixIconImage` helpers so custom and SF Symbol icons render consistently in the picker, mix rows, and sidebar entries.
- **Mix icon sizing**: Matched mix icon sizing to sound-row sizing and normalized the palm icon optical scale to align with SF Symbols.
- **ContentView refactor**: Broke the oversized `ContentView` into smaller focused components (`ContentSections`, `ContentToolbar`, `ToolbarBridges`, `ScrollStateStore`, `SidebarLayout`) to improve maintainability and reduce complexity.

### Fixed
- **Timer (header button)**: Fixed the timer header control so clicking it reliably opens the `Set timer` window.
- **Sidebar resize feel**: Stabilized the left sidebar drag by clamping/respecting the window width throughout the gesture and preventing content width recomputation until the drag ends, eliminating the jitter seen during live resizing.
- **Sound row (icon stability)**: Removed the selection-state icon animation and fixed the icon weight so selecting a sound no longer produces a jumpy/bouncy visual.

---

## [1.0.0] – 2026-02-10

### Added
- **Timer**: New timer panel with a modern UI.
- **Options (start collapsed)**: New preference for cold start with categories collapsed. Persistent key and `resetAll` support (PersistenceService). Toggle in Options with accessibility and help text (OptionsView). ContentView: Sounds and Mixes start collapsed or expanded per preference; Custom Mixes always starts expanded. Mixes “Collapse all” / “Expand all” now targets only non-custom categories (button state and action exclude Custom Mixes) (ContentView).
- **Localization (future translation)**: Added the 20 missing keys to `Localizable.strings` (en and es): `media_key_*`, `timer_*` (custom, remaining, finished, start, placeholder), `accent_color_*` (system plus color names), `expand_section`, `collapse_section`. All keys from `L10n.swift` are now present in both languages. Prepares the app for future translation to additional languages.

### Changed
- **Release**: The application leaves beta; this is the first stable release (1.0).
- **Media keys (MediaKeyHandler)**: Added `isCurrentlyPlaying` using `MPNowPlayingInfoCenter.default().playbackState`. `playCommand` now only invokes `onTogglePlayPause` when not currently playing; `pauseCommand` only invokes it when playing. This avoids redundant toggles when the system media key state matches the app state (MediaKeyHandler.swift).
- **Sidebar**: Resizing behavior of the left sidebar was updated for smoother, more fluid interaction.
- **Layout (live resize)**: `contentAreaWidth` now updates during sidebar drag (0.5 threshold to reduce noise); main content uses `sidebarWidth` in real time. `updateSidebarForWindowWidth` logic and comments reworked; added `mainContentMinWidth` and dynamic `maxSidebarWidth` from total window width (ContentView).
- **Sidebar (drag & drop)**: Insertion indicator uses `info.location.y` for `insertBefore` (cursor position), not drag direction. Drag restricted to internal `UTType` types with typed provider; separate `onDrop`/`validateDrop` for sounds vs mixes (SidebarView).
- **Sidebar (performance)**: Preset lookup by id moved to the store (`presetsById`); SidebarView uses it for recent/favorite lists to reduce recomputes (SoundStore, SidebarView).
- **Resize cursor**: Replaced simple hover with `onContinuousHover` and cleanup in `onDisappear`; added state guard for balanced push/pop of cursor (ContentView).
- **Resize snap**: Snap value set to 3 for smoother sidebar resize (ContentView).
- **Main content (single section)**: Replaced ZStack-with-opacity by conditional rendering so only one main section (Sounds or Mixes) is in the view tree at a time, avoiding two live trees (ContentView).
- **Scroll restoration**: Removed sleeps and duplicate `scrollPosition` assignments; single-step restore with `Task.yield()`. Simplified `onAppear` for both lists to avoid a second deferred restore. Removed unused state `forceInitialSoundsTop` / `forceInitialMixesTop` (ContentView).
- **Heavy actions (no animation wrap)**: `toggleSound()` no longer wraps select/unselect in `withAnimation` (SoundRow). Mix row tap no longer wraps `applyMix` in `withAnimation` (MixCategoryView). Reduces unnecessary animation around audio and mix-apply work.
- **Floating player (relayout)**: Removed redundant internal `GeometryReader`s in the three containers (glass, fallback, solid). Content now receives `barWidth` from the outer `GeometryReader`, reducing relayout (FloatingPlayerPanelView).
- **Currently playing (cache)**: Added `playingSoundsCache` state; updated when `store.sounds` changes and in `onAppear`. The "Currently playing" section now renders from cache instead of recalculating/sorting on every render (e.g. every timer tick) (ContentView). Improves performance and reduces cpu wakes. 
- **Launch (deferred reconfig)**: Removed redundant delayed `configureExistingMainWindow()` calls at +0.2s and +1.2s in `applicationDidFinishLaunching` (MoodistApp).
- **Window frame restoration**: Restore frame once in the next runloop via `DispatchQueue.main.async`; removed `frameRestoreDelay` and 300ms `asyncAfter`. In `applyRestoredFrame(to:)`, compare current frame with target and call `window.setFrame` only when the difference is > 1 point; added `frameDistance(_:_:)` helper (MoodistApp).
- **Main window**: Minimum height aligned with AppKit (`.frame(minHeight: 600)` instead of 480) (ContentView). AppKit frame autosave disabled (`setFrameAutosaveName` removed) to avoid double persistence; manual save/restore with `saveFrame(usingName:)` / `setFrameUsingName` is unchanged (MoodistApp).
- **Mixes layout**: Mixes now uses the same top padding as Sounds (`mixesScrollTopPadding` returns `contentTopPadding` instead of only `titlebarContentInset`), so both sections start aligned (ContentView).
- **Options (UI)**: Pill-style (capsule) buttons for Data/Updates/About actions and toolbar Close; new button style (OptionsView). Options window is transparent when transparencies are enabled: Form uses `VisualEffectBackground(material: .sidebar)` instead of solid background; window `isOpaque`/`backgroundColor` set for real transparency (OptionsView).
- **Options (Recent counts)**: Recent mixes and Recent sounds use sliders (range 5–15, step 1) instead of steppers (OptionsView). Persistence validation updated so the app respects 5…15 everywhere (PersistenceService). L10n footers and Localizable.strings (en/es) updated for the 5–15 range (L10n, Localizable.strings).

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

[Unreleased]: https://github.com/jsgrrchg/MoodistMac/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/jsgrrchg/MoodistMac/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/jsgrrchg/MoodistMac/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/jsgrrchg/MoodistMac/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/jsgrrchg/MoodistMac/releases/tag/v1.0.0
[BETA 5]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-4...Beta-5
[BETA 4]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-4
[Beta 3]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-3
[Beta 2]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-1...Beta-2
[Beta 1]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-1
