# Moodist

**Sonidos ambientales para concentrarte y relajarte.**

Moodist es una app nativa para macOS que te permite mezclar y reproducir sonidos ambientales—lluvia, naturaleza, cafés, ruido blanco, tonos binaurales y más—para concentrarte, relajarte o dormir. Combina sonidos individuales, usa mezclas curadas, guarda presets, exporta e importa preferencias y controla todo desde la barra de menú o el teclado.

**Moodist original** (web): [remvze/moodist](https://github.com/remvze/moodist) — *Ambient sounds for focus and calm.*

![macOS](https://img.shields.io/badge/macOS-15.0+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## Características

### Sonidos y mezclas
- **89 sonidos** en 9 categorías: Nature, Rain, Animals, Urban, Places, Transport, Things, Noise y Binaural
- **81 mezclas curadas** en 10 categorías temáticas: Nature & Relaxation, Walking, Sea & Coast, Forest Fire & Night, Rain & Storm, Focus & Study, Travel & Motion, Sleep & Noise, Places & Ambience y Custom Mixes
- **Mezclas y presets propios** — crea combinaciones, guárdalas como presets y recupéralas cuando quieras
- **Favoritos** — marca sonidos y mezclas como favoritos para acceder rápido desde la barra lateral y el menú
- **Mezclas recientes** — la barra lateral muestra las últimas mezclas usadas (configurable entre 10 y 15)

### Reproducción y control
- **Volumen global y por sonido** — volumen maestro y sliders individuales para cada sonido activo
- **Timer de sueño** — duración con presets o minutos personalizados; al terminar se detiene la reproducción y se muestra una notificación
- **Tecla de medios opcional** — la tecla «Siguiente» del teclado o auriculares puede cargar una mezcla aleatoria

### Interfaz y ventanas
- **Barra de menú** — icono opcional en la barra de menú con acceso rápido a reproducción, timer, sonidos y mezclas
- **Reproductor flotante** — ventana compacta que permanece encima para usar la app sin distracciones
- **Búsqueda** — localiza sonidos por nombre (⌘F)

### Apariencia
- **Tema** — claro, oscuro o automático según el sistema
- **Tamaño de texto** — pequeño, medio, grande o extra grande
- **Color de acento** — Multicolor (sistema) o 9 colores fijos: azul, púrpura, rosa, rojo, naranja, amarillo, verde, grafito
- **Transparencias** — opción para desactivar transparencias y efectos de cristal esmerilado

### Datos y preferencias
- **Exportar preferencias** — guarda en un archivo JSON tus mezclas personalizadas, mezclas favoritas y sonidos favoritos (desde Opciones o menú Moodist)
- **Importar preferencias** — restaura esas preferencias desde un archivo exportado
- **Restablecer selección y favoritos** — borra solo la selección actual y la lista de favoritos
- **Restaurar todo a valores por defecto** — restablece selección, favoritos y volumen global

### Accesibilidad e idioma
- **Localización** — inglés y español (además del idioma del sistema)
- **Atajos de teclado** — Play/Pause (⌘R), Shuffle (⌘S), Siguiente mezcla (⌘N), Deseleccionar todo (⌘U), Buscar (⌘F), Opciones (⌘,)

---

## Requisitos

- **macOS** 15.0 (Sequoia) o posterior
- **Xcode** 14.0 o posterior (para compilar desde código fuente)
- **Swift** 5.0

---

## Compilar desde código fuente

1. Clona el repositorio:
   ```bash
   git clone https://github.com/jsgrrchg/MoodistMac.git
   cd MoodistMac
   ```
2. Abre el proyecto en Xcode:
   ```bash
   open Moodist.xcodeproj
   ```
3. Selecciona el scheme **MoodistMac** y compila (⌘B).
4. Ejecuta la app (⌘R) o usa **Product → Archive** para generar una build distribuible.

No hay dependencias externas; el proyecto usa solo frameworks del sistema (SwiftUI, AppKit, AVFoundation, etc.).

---

## Estructura del proyecto

```
MoodistMac/
├── Moodist/
│   ├── MoodistApp.swift          # Entrada, escenas, comandos de menú
│   ├── Data/                     # Datos de sonidos y mezclas
│   ├── Models/                   # Sound, Mix, Preset, TimerItem, ExportedPreferences, etc.
│   ├── Store/                    # SoundStore (estado de reproducción)
│   ├── Services/                 # Audio, persistencia, timer, export/import de preferencias
│   ├── Views/                    # Vistas SwiftUI (barra lateral, contenido, opciones, reproductor)
│   ├── Helpers/                  # L10n, tema, colores, modificadores
│   ├── sounds/                   # Assets de audio (MP3/WAV)
│   ├── Assets.xcassets/          # Icono y color de acento
│   └── en.lproj / es.lproj/      # Cadenas localizadas
├── Moodist.xcodeproj/
└── README.md
```

---

## Uso (referencia rápida)

| Acción              | Atajo   |
|---------------------|---------|
| Play / Pause        | ⌘R      |
| Shuffle             | ⌘S      |
| Siguiente mezcla    | ⌘N      |
| Deseleccionar todo  | ⌘U      |
| Buscar              | ⌘F      |
| Opciones            | ⌘,      |

Los presets del timer y la duración personalizada están en el menú **Timer** y (si está activado) en la barra de menú. **Exportar preferencias** e **Importar preferencias** están en el menú de la app y en Opciones → Datos.

---

## Licencia

Este proyecto es de código abierto. Consulta el archivo [LICENSE](LICENSE) del repositorio para más detalles.

---

## Contribuir

Las contribuciones son bienvenidas. Abre primero un issue para cambios grandes y mantén el estilo y la estructura del código existentes.
