# Moodist

## Sequoia:

<img width="962" height="1057" alt="Captura de pantalla 2026-02-04 a las 18 05 47" src="https://github.com/user-attachments/assets/7d3996aa-5d22-4154-8d57-e652fb229b2e" />

## Tahoe: 

<img width="962" height="969" alt="Captura de pantalla 2026-02-05 a las 11 33 29 a  m" src="https://github.com/user-attachments/assets/f1e8ed4c-55b4-4094-98f8-05d508ae190c" />


**Ambient sounds for focus and relaxation.**

Moodist is a native macOS and iPhone app that lets you mix and play ambient sounds—rain, nature, cafés, white noise, binaural tones, and more—to help you focus, relax, or sleep. Combine individual sounds, use curated mixes, save presets, export and import preferences, and control everything from the menu bar or keyboard.

For non technical users, you can download the latest release from the releases page, you will find a MoodistMac.app inside a zip file of the same name, simply extract and move the binary to your Applications folder.

Inspired by the original Moodist web app [remvze/moodist](https://github.com/remvze/moodist) — *Ambient sounds for focus and calm.* 

[Support Moodist for MacOS – Buy me a coffee ☕️](https://buymeacoffee.com/jsgrrchg)

![macOS](https://img.shields.io/badge/macOS-15.0+-black?style=flat-square&logo=apple)
![iOS](https://img.shields.io/badge/iOS-26.0+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6_toolchain-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)


---

## Features

### Sounds and mixes
- **131 sounds** in 10 categories: Nature, Rain, Animals, Urban, Places, Transport, Things, Noise, Binaural, and Military
- **123 curated mixes** in 11 categories: Nature & Relaxation, Walking, Sea & Coast, Forest Fire & Night, Rain & Storm, Focus & Study, Travel & Motion, Sleep & Noise, Places & Ambience, Military, and Custom Mixes
- **Collapse / Expand all** — one-tap button to collapse or expand all sound or mix categories in the list
- **Custom mixes and presets** — create combinations, save them as presets (with icon selector), and recall them anytime
- **Favorites** — star sounds and mixes for quick access from the sidebar and menu; reorder favorites by drag and drop
- **Recent** — separate recent mixes and sounds (each configurable between 5 and 15)

### Playback and control
- **Global and per-sound volume** — master volume plus individual sliders for each active sound
- **Sleep timer** — duration with presets or custom minutes; playback stops and a notification appears when time is up
- **Optional media key** — the “Next” key on your keyboard or headphones can load a random mix

### macOS interface and windows
- **Menu bar** — optional menu bar icon with quick access to playback, timer, sounds, and mixes
- **Floating player** — compact always-on-top window with stop (unselect all), play, shuffle, next mix, volume, and scrolling mix name (marquee)
- **Search** — find sounds by name (⌘F)
- **Sidebar** — always visible; favorites and recent mixes/sounds with configurable list sizes (5–15)

### Appearance
- **Theme** — light, dark, or automatic based on system
- **Accent color** — Multicolor (system) or 9 fixed colors: blue, purple, pink, red, orange, yellow, green, graphite (default: graphite)
- **Transparencies** — option to disable transparencies and frosted glass effects

### Data and preferences
- **Export preferences** — save your custom mixes, favorite mixes, and favorite sounds to a JSON file (from Options or Moodist menu)
- **Import preferences** — restore those preferences from an exported file
- **Reset selection and favorites** — clear only the current selection and favorites list
- **Restore all to defaults** — reset selection, favorites, and global volume
- **Check for updates** — from Options or the app menu (when using a Sparkle-enabled build)

### Accessibility
- **Keyboard shortcuts** — Play/Pause (⌘R), Shuffle (⌘S), Next mix (⌘N), Unselect all (⌘U), Search (⌘F), Options (⌘,)

---

## Requirements

- **macOS** 15.0 (Sequoia) or later
- **Xcode** 26.2 or later (stable recommended; includes Swift 6)
- **iPhone** iOS 26.0 or later; iPad is not a supported target
- **Tests** require an installed iOS 26 simulator runtime

---

## Building from source

1. Clone the repository:
   ```bash
   git clone https://github.com/jsgrrchg/MoodistMac.git
   cd MoodistMac
   ```
2. Open the project in Xcode:
   ```bash
   open Moodist.xcodeproj
   ```
3. Select **MoodistMac** for desktop, or **MoodistIOS** with an iPhone simulator, and build (⌘B).
4. Run the app (⌘R) or use **Product → Archive** to create a distributable build.

Both apps consume the local Swift package **MoodistKit**. macOS also uses **Sparkle** for updates; iOS uses system frameworks and excludes Sparkle/AppKit. Audio files and translations live in the package and are bundled for offline use.

iOS is implemented but not published. Physical-device endurance, routes, accessibility, asset redistribution evidence and signing remain open gates. See [iOS development and validation](docs/ios/README.md), [parity](docs/ios/PARITY.md) and [release readiness](docs/ios/RELEASE.md).

---

## Project structure

```text
Moodist/                         macOS app, windows, menus and adapters
MoodistIOS/                      iPhone app, Liquid Glass UI and iOS adapters
Packages/MoodistKit/              shared catalog, audio, state, persistence and timers
  Sources/MoodistKit/Resources/   131 audio files, shared images, en/es/pt-BR strings
MoodistTests/                    macOS app integration tests
MoodistIOSTests/                 iOS session and real-engine integration tests
MoodistIOSUITests/               iPhone user-flow tests
Moodist.xcodeproj/               MoodistMac and MoodistIOS shared schemes
scripts/ios/                     catalog, bundle, platform and iOS release validation
docs/ios/                        usage, parity, QA, asset inventory and releases
```

---

## iPhone usage

Use **Sounds**, **Mixes** and **Library** to select audio and organize favorites. Tap the persistent mini-player to open volume controls, selected tracks, sleep and automatic mix timers. Settings provides appearance, languages and interoperable preference files. The iPhone UI uses native Liquid Glass with reduced-transparency adaptations. Read the [mobile guide](docs/ios/USAGE.md) for audio policies and background limits.

## macOS usage (quick reference)

| Action        | Shortcut   |
|---------------|------------|
| Play / Pause  | ⌘R         |
| Shuffle       | ⌘S         |
| Next mix      | ⌘N         |
| Unselect all  | ⌘U         |
| Search        | ⌘F         |
| Options       | ⌘,         |

Timer presets and custom duration are in the **Timer** menu and (if enabled) the menu bar. **Export preferences** and **Import preferences** are in the app menu and under Options → Data.

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

### Third-party assets

The code license does not grant rights to bundled third-party audio. The [per-file rights inventory](docs/ios/ASSET_RIGHTS.md) currently requires provenance for all 131 sounds before iOS distribution.
Some sounds used in this project are sourced from third-party providers and are subject to different licenses:

Sounds licensed under the Pixabay Content License: Pixabay Content License
Sounds licensed under CC0: Creative Commons Zero License

Some sound effects are from the [BBC Sound Effects](https://sound-effects.bbcrewind.co.uk/) library ([licensing](https://sound-effects.bbcrewind.co.uk/licensing)). © BBC.

---

## Contributing

Contributions are welcome. Please open an issue first to discuss larger changes, and keep the existing code style and structure.
