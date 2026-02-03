# MoodistMac
A native MacOS ambient sound app. 
# Moodist

**Ambient sounds for focus and calm.**

Moodist is a native macOS app that lets you mix and play ambient sounds—rain, nature, cafés, white noise, binaural tones, and more—to help you focus, relax, or sleep. Combine individual sounds, use curated mixes, save presets, and control everything from the menu bar or keyboard.

![macOS](https://img.shields.io/badge/macOS-15.0+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## Features

- **80+ sounds** in 9 categories: Nature, Rain, Animals, Urban, Places, Transport, Things, Noise, and Binaural
- **Curated mixes** — one-tap combinations like “Zen Garden”, “Rainy Afternoon”, “Deep Sleep”, “Productive Cafe”, and 50+ more
- **Custom mixes & presets** — build your own combinations, save them as presets, and recall them anytime
- **Favorites** — star sounds and mixes for quick access from the sidebar and menu
- **Sleep timer** — set a duration (presets or custom minutes); playback stops and a notification fires when time is up
- **Global and per-sound volume** — master volume plus individual sliders for each active sound
- **Menu bar** — optional menu bar icon with quick access to playback, timer, sounds, and mixes
- **Floating player** — compact window that stays on top for minimal distraction
- **Search** — find sounds by name (⌘F)
- **Appearance** — light, dark, or automatic; accent color; text size; option to disable transparencies
- **Localization** — English and Spanish (plus system language)
- **Keyboard shortcuts** — Play/Pause (⌘R), Shuffle (⌘S), Next mix (⌘N), Unselect all (⌘U), Search (⌘F), Options (⌘,)
- **Optional media key** — use the “Next track” key to load a new random mix

---

## Requirements

- **macOS** 15.0 (Sequoia) or later  
- **Xcode** 14.0 or later (for building from source)  
- **Swift** 5.0

---

## Building from source

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/moodist-mac.git
   cd moodist-mac
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
│   ├── Models/                   # Sound, Mix, Preset, TimerItem, etc.
│   ├── Store/                    # SoundStore (playback state)
│   ├── Services/                 # Audio, persistence, timer notifications
│   ├── Views/                    # SwiftUI views (sidebar, content, options, player)
│   ├── Helpers/                  # L10n, theme, colors, modifiers
│   ├── sounds/                   # Bundled audio assets (MP3/WAV)
│   ├── Assets.xcassets/          # App icon and accent
│   └── en.lproj / es.lproj/      # Localized strings
├── Moodist.xcodeproj/
└── README.md
```

---

## Usage (quick reference)

| Action            | Shortcut   |
|-------------------|------------|
| Play / Pause      | ⌘R         |
| Shuffle           | ⌘S         |
| Next mix          | ⌘N         |
| Unselect all      | ⌘U         |
| Search            | ⌘F         |
| Options           | ⌘,         |

Timer presets and custom duration are available from the **Timer** menu and (if enabled) the menu bar.

---

## License

This project is open source. See the [LICENSE](LICENSE) file in the repository for details.

---

## Contributing

Contributions are welcome. Please open an issue first to discuss larger changes, and ensure any code follows the existing style and structure.
