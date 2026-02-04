# Changelog

All notable changes to Moodist (macOS) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- (Changes not yet released go here.)

### Changed
- (Nothing yet.)

### Fixed
- (Nothing yet.)

### Removed
- (Nothing yet.)

---

## [Beta 2] – 2025-02-04

### Added
- **Actualizaciones**
  - Integración con Sparkle: comprobación automática de actualizaciones
  - Menú “Buscar actualizaciones…” en el menú de la app (después de Acerca de)
  - Sección “Actualizaciones” en Opciones con botón para comprobar manualmente
  - Appcast y firma EdDSA configurados en `Info.plist` para actualizaciones seguras
- **Ventana principal**
  - La posición y el tamaño de la ventana principal se recuerdan entre sesiones
  - Al cerrar con el botón rojo la ventana se oculta; al hacer clic en el icono del Dock se vuelve a mostrar

### Changed
- **Mixes**: Se optimizaron los mixes existentes
- **Rendimiento**: Mejoras generales en el rendimiento de la app

### Fixed
- (Nada destacado.)

### Removed
- **Mixes**: Se eliminaron algunos mixes

### Requirements
- macOS 15.0 (Sequoia) o posterior
- Swift 5.0, SwiftUI, Sparkle (actualizaciones)

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

[Unreleased]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-2...HEAD
[Beta 2]: https://github.com/jsgrrchg/MoodistMac/compare/Beta-1...Beta-2
[Beta 1]: https://github.com/jsgrrchg/MoodistMac/releases/tag/Beta-1
