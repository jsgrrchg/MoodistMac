# iOS parity tracking

Status: implementation available for all P01–P26. Full parity acceptance remains open: physical-device, desktop-runtime, accessibility and distribution evidence is still required. Automated checks are not proof of every manual interaction.

| ID | Función del escritorio | Implementación/equivalente iPhone | Commits |
| --- | --- | --- | --- |
| P01 | Catálogo completo y categorías | Mismos datos y audios locales; mismos IDs | C01, C03, C04, C12 |
| P02 | Selección simultánea de sonidos | Selección múltiple y lista de sonidos activos | C05, C12, C13 |
| P03 | Play/pausa, quitar sonido, deseleccionar todo | Acciones separadas, conservando la selección al pausar | C05, C13 |
| P04 | Volumen global e individual | Volumen del mezclador y sliders individuales; separado del volumen físico del teléfono | C05, C13 |
| P05 | Mezclas temáticas y reconocimiento de mezcla activa | Catálogo, nombre/icono actual y aplicación completa de volúmenes | C05, C12, C13 |
| P06 | Shuffle | Cuatro sonidos aleatorios y sus volúmenes, según el algoritmo actual | C01, C05, C13 |
| P07 | Siguiente mezcla aleatoria | No repetir la actual cuando exista alternativa; gestionar conjuntos vacíos o de una mezcla | C05, C09, C13 |
| P08 | Fundidos entre mezclas | 1,5 s; conservar pistas comunes y cancelar transiciones obsoletas | C05, C08, C23 |
| P09 | Mezclas personalizadas | Guardar selección; editar nombre/icono; borrar; añadir sonido a existente o crear desde un sonido | C15 |
| P10 | Favoritos de sonidos y mezclas, ordenables | Biblioteca con reordenación táctil y alternativa accesible | C14 |
| P11 | Recientes de sonidos y mezclas | Secciones independientes y límites 5–15, conservados entre lanzamientos | C14, C18 |
| P12 | Buscar sonidos; plegar categorías | Búsqueda localizada, plegar/desplegar todo y ajuste de plegado al iniciar | C12, C18 |
| P13 | Restaurar navegación/scroll | Posición por sección y contexto de búsqueda; recuperación al volver a una pestaña | C12 |
| P14 | Temporizador de apagado | Presets, duración h:min:s, cancelar, cuenta regresiva y notificación | C10, C16 |
| P15 | Auto-mix/Pomodoro | Intervalos 5–60 min, cancelar, cuenta regresiva y solo mezclas propias | C10, C17 |
| P16 | Controles de auriculares y tecla siguiente opcional | Play/pausa/siguiente mediante comandos del sistema y ajuste correspondiente | C09, C18 |
| P17 | Reproductor flotante, barra de menús y menú Dock | Reproductor persistente dentro de la app; controles del sistema fuera de ella cuando iOS se los asigne | C09, C11, C13 |
| P18 | Menús y atajos de teclado | Acciones táctiles/contextuales; mantener atajos compatibles con teclado externo | C12–C19, C21 |
| P19 | Apariencia clara/oscura/automática y acentos | Preferencias equivalentes y colores semánticos con Liquid Glass | C11, C18 |
| P20 | Desactivar transparencias | Reducir efectos propios; respetar la accesibilidad del sistema y explicar el alcance sobre barras nativas | C11, C18, C21 |
| P21 | Idioma del sistema, inglés, español y portugués de Brasil | Selector y contenido localizado sin forzar el cierre de la app | C04, C18, C20 |
| P22 | Importar/exportar preferencias | JSON v1 interoperable mediante Archivos y compartir | C02, C19 |
| P23 | Reset de selección/favoritos y restauración completa | Dos acciones distintas, confirmación y alcance documentado | C02, C18 |
| P24 | Acerca de, versión, créditos y soporte | Pantalla de información móvil; revisar por separado cualquier enlace de aportes antes de publicar | C18, C22, C26 |
| P25 | Actualizaciones Sparkle | App Store/TestFlight en iOS; conservar Sparkle en Mac | C06, C25 |
| P26 | Continuar el audio al usar otras apps | Sesión iOS, pantalla bloqueada e interrupciones; política para mezclar audio externo | C07–C10, C23 |

No existe una copia literal en iPhone de ventanas siempre encima, icono de barra de menús, tamaño/posición de ventanas ni gestos de trackpad. Sus ajustes exclusivos no deben aparecer como interruptores sin efecto. Widgets y Live Activities podrían ampliar los accesos rápidos después; no son necesarios para reproducir o cambiar mezclas desde la app.


## Evidence by feature

| IDs | Implementation / automated evidence | Remaining acceptance |
| --- | --- | --- |
| P01, P05 | CatalogTests, ResourceTests: 131 sounds/123 mixes, every file opens; catalog audit | Visual categories in all locales |
| P02–P04, P06–P07 | StoreTests selection/playback/shuffle; real-engine integration; UI select/save/recall/pause | Actual perceived volume, routes and edge-state interaction |
| P08 | Shared engine crossfade retained; engine rebuild tested | Audible 1.5-second transitions and rapid changes on hardware |
| P09 | UI test creates/recalls a custom mix; StoreTests preset deletion | Manual editing, deletion confirmation and add-to-existing flows |
| P10–P11 | UI favorite flow; store recent/deletion tests; LibraryView ordering | Drag/accessibility reorder and persistence across real upgrades |
| P12–P13 | CatalogViews search/collapse and repository-backed anchors | Screen sizes, navigation restoration and localized search |
| P14–P15 | TimerTests: deadlines, missed ticks, sleep dominance, 96 simulated rotations; UI sleep navigation | 30-minute/eight-hour hardware run and notification permissions |
| P16–P17, P26 | AudioSessionTests, EngineIntegrationTests, interruption intent tests; native mini-player and Now Playing adapter | Lock screen, calls/Siri, headphones, Bluetooth/AirPlay and other players |
| P18 | Touch/contextual controls and supported command shortcuts; UI navigation | External keyboard and VoiceOver audit |
| P19–P20 | Dark/large-text UI flow; native glass and explicit opaque fallback | Real contrast, Reduce Transparency/Motion and every accent |
| P21 | Localization script verifies 543 keys/format placeholders in en/es/pt-BR | Full manual language switch and system-language flows |
| P22 | InteroperabilityTests and StoreTests malformed/future/unknown data; FileDocument adapter | Files providers, share destinations and real Mac/iPhone file exchange |
| P23 | Shared reset actions and Settings confirmations | Both reset scopes through actual UI |
| P24 | Settings About/Privacy, resource credits inventory and app version | Hosted support/privacy, final credits and legal provenance |
| P25 | Independent release-tag/metadata tests and unsigned archive validation | Signed archive, Apple processing, TestFlight install/update |

Platform equivalences are intentional: app-owned player plus iOS media controls replaces Mac windows/menu-bar/Dock surfaces; App Store/TestFlight replaces Sparkle. iOS cannot guarantee exact timer callbacks while suspended/terminated. The mini-player uses a native Liquid Glass safe-area inset after repeated tap failures in the iOS 26 tab accessory; it remains persistent above navigation tabs.

See [QA](QA.md) for the environment, measured scope and open sign-offs. No physical or store requirement is marked complete based only on source review.
