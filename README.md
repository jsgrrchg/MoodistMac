# Moodist

## Sequoia:

<img width="962" height="1057" alt="Captura de pantalla 2026-02-04 a las 18 05 47" src="https://github.com/user-attachments/assets/7d3996aa-5d22-4154-8d57-e652fb229b2e" />

## Tahoe: 

<img width="962" height="969" alt="Captura de pantalla 2026-02-05 a las 11 33 29 a  m" src="https://github.com/user-attachments/assets/f1e8ed4c-55b4-4094-98f8-05d508ae190c" />


**Ambient sounds for focus and relaxation.**

Moodist is a native macOS app that lets you mix and play ambient sounds—rain, nature, cafés, white noise, binaural tones, and more—to help you focus, relax, or sleep. Combine individual sounds, use curated mixes, save presets, export and import preferences, and control everything from the menu bar or keyboard.

Inspired by the original Moodist web app [remvze/moodist](https://github.com/remvze/moodist) — *Ambient sounds for focus and calm.* 

[Support Moodist for MacOS – Buy me a coffee ☕️](https://buymeacoffee.com/jsgrrchg)

![macOS](https://img.shields.io/badge/macOS-15.0+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)


---

## Features

### Sounds and mixes
- **131 sounds** in 10 categories: Nature, Rain, Animals, Urban, Places, Transport, Things, Noise, Binaural, and Military
- **126 curated mixes** in 11 categories: Nature & Relaxation, Walking, Sea & Coast, Forest Fire & Night, Rain & Storm, Focus & Study, Travel & Motion, Sleep & Noise, Places & Ambience, Military, and Custom Mixes
- **Collapse / Expand all** — one-tap button to collapse or expand all sound or mix categories in the list
- **Custom mixes and presets** — create combinations, save them as presets (with icon selector), and recall them anytime
- **Favorites** — star sounds and mixes for quick access from the sidebar and menu; reorder favorites by drag and drop
- **Recent** — sidebar shows recent mixes and recent sounds (each configurable between 10 and 15)

### Playback and control
- **Global and per-sound volume** — master volume plus individual sliders for each active sound
- **Sleep timer** — duration with presets or custom minutes; playback stops and a notification appears when time is up
- **Optional media key** — the “Next” key on your keyboard or headphones can load a random mix

### Interface and windows
- **Menu bar** — optional menu bar icon with quick access to playback, timer, sounds, and mixes
- **Floating player** — compact always-on-top window with stop (unselect all), play, shuffle, next mix, volume, and scrolling mix name (marquee)
- **Search** — find sounds by name (⌘F)
- **Sidebar** — always visible; favorites and recent mixes/sounds with configurable list sizes (10–15)

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
- **Xcode** 14.0 or later (for building from source)
- **Swift** 5.0

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
3. Select the **MoodistMac** scheme and build (⌘B).
4. Run the app (⌘R) or use **Product → Archive** to create a distributable build.

No external dependencies; the project uses only system frameworks (SwiftUI, AppKit, AVFoundation, etc.).

---

## Project structure

```
MoodistMac/
├── Moodist/
│   ├── MoodistApp.swift          # App entry, scenes, menu commands
│   ├── Data/                     # Sounds and mixes data
│   ├── Models/                   # Sound, Mix, Preset, TimerItem, ExportedPreferences, etc.
│   ├── Store/                    # SoundStore (playback state)
│   ├── Services/                 # Audio, persistence, timer, preference export/import
│   ├── Views/                    # SwiftUI views (sidebar, content, options, player)
│   ├── Helpers/                  # L10n, theme, colors, modifiers
│   ├── sounds/                   # Audio assets (MP3/WAV)
│   ├── Assets.xcassets/          # App icon and accent color
│   └── en.lproj / es.lproj/      # Localized strings
├── Moodist.xcodeproj/
└── README.md
```

---

## Usage (quick reference)

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

⚠️ Third-Party Assets
Some sounds used in this project are sourced from third-party providers and are subject to different licenses:

Sounds licensed under the Pixabay Content License: Pixabay Content License
Sounds licensed under CC0: Creative Commons Zero License

Some sound effects are from the [BBC Sound Effects](https://sound-effects.bbcrewind.co.uk/) library ([licensing](https://sound-effects.bbcrewind.co.uk/licensing)). © BBC.

---

## Contributing

Contributions are welcome. Please open an issue first to discuss larger changes, and keep the existing code style and structure.
