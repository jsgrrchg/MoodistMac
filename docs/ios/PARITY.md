# iOS parity tracking

Status: implementation in progress. No physical-device validation yet.

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

