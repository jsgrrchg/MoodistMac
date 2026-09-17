# App Store metadata draft — not submitted

Version 1.0.0 (1), iPhone, iOS 26+. These texts and screenshots require final editorial/device review before upload. Do not publish while asset rights or release gates are unresolved.

| Locale | Name | Subtitle | Description |
| --- | --- | --- | --- |
| en-US | Moodist | Ambient sounds for focus | Create your own background soundscape with 131 offline sounds and 123 curated mixes. Blend nature, rain, cafés and noise, adjust each sound, and save your favorite combinations. Use sleep and automatic mix timers, organize favorites, and transfer preferences with Moodist for Mac. A native iPhone interface with Liquid Glass, appearance options and accessible controls. |
| es | Moodist | Sonidos para concentrarte | Crea tu ambiente con 131 sonidos sin conexión y 123 mezclas. Combina naturaleza, lluvia, cafeterías y ruido, ajusta cada sonido y guarda tus combinaciones favoritas. Usa el apagado programado y la rotación de mezclas, organiza favoritos y transfiere preferencias con Moodist para Mac. Interfaz nativa para iPhone con Liquid Glass y opciones de apariencia y accesibilidad. |
| pt-BR | Moodist | Sons para se concentrar | Crie seu ambiente com 131 sons offline e 123 mixes. Combine natureza, chuva, cafés e ruído, ajuste cada som e salve suas combinações favoritas. Use o temporizador de desligamento e a troca automática de mixes, organize favoritos e transfira preferências com o Moodist para Mac. Interface nativa para iPhone com Liquid Glass e opções de aparência e acessibilidade. |

Suggested keywords: ambient,focus,rain,nature,sleep,sounds,noise. Review character limits in App Store Connect before submission.

## Support, privacy and review information

- Proposed support URL: [repository issues](https://github.com/jsgrrchg/MoodistMac/issues). Verify its public accessibility and provide a monitored support contact before submitting.
- Privacy text: [PRIVACY.md](PRIVACY.md). A public hosted privacy URL is **not configured**; publish/verify one before App Store metadata is completed.
- No login is required. Reviewer can open Sounds, select River, open the mini-player, adjust volume, save a custom mix and find it in Library. Open the player for sleep and automatic rotation; Settings contains data import/export.
- Background-audio reason: the user's chosen ambient mix continues while the screen is locked or another app is used. The app uses the playback audio session and audio background mode for audible playback. Timers do not act as a general background task service.
- Notifications are optional local sleep-timer notifications. No advertising/tracking/analytics SDK is included. Data-collection and privacy-manifest answers must match the final archive and hosted policy.
- Complete reviewer contact, age rating, category, export compliance and beta information with the owner's actual details. Do not invent contact or rights information.

## Screenshot material

Real simulator screenshots from iOS 26.2 UI tests are in [screenshots](screenshots/README.md): player, library, settings and sleep. They use a synthetic “Evening test” mix. These are QA captures, not a complete store submission set: recapture final app UI in the required device sizes, all storefront languages and stable presentation states. The original catalog screenshot predates the final mini-player placement and is baseline evidence only.

Inherited AppIcon is bundled, but its PNG has an alpha channel. Validate an opaque distribution asset and desired dark/tinted variants before submission; do not treat a successful simulator build as icon acceptance.
