# Instrucciones para Release Beta 5

## ✅ Pasos Completados

1. ✅ Versión actualizada a Beta 5 en `project.pbxproj`
2. ✅ CHANGELOG.md actualizado con fecha de release
3. ✅ Item de Beta 5 añadido al `appcast.xml` (con placeholders)
4. ✅ Código commiteado y pusheado a GitHub

## 📋 Pasos Restantes (Manuales)

### Paso 1: Archivar y Exportar la App en Xcode

1. Abre el proyecto en Xcode
2. Selecciona el scheme **MoodistMac** y configuración **Release**
3. Ve a **Product → Archive**
4. Cuando termine, se abrirá el Organizer
5. Selecciona el archive y haz clic en **Distribute App**
6. Selecciona **Copy App** (o **Developer ID** si distribuyes fuera del Mac App Store)
7. Exporta a una carpeta (por ejemplo `~/Desktop/export/`)
8. Anota la ruta completa del `MoodistMac.app` exportado

### Paso 2: Crear Zip y Firmar con Sparkle

Ejecuta el script helper desde la raíz del proyecto:

```bash
cd /Users/jfg/Documents/DEVELOPMENT/MOOOODIST/MoodistMac
./scripts/prepare-release.sh /ruta/completa/al/MoodistMac.app
```

El script:
- Creará `MoodistMac.zip` en tu escritorio
- Lo firmará con Sparkle usando tus claves
- Actualizará automáticamente `appcast.xml` con la firma y el tamaño

### Paso 3: Commit y Push del Appcast Actualizado

```bash
cd /Users/jfg/Documents/DEVELOPMENT/MOOOODIST/MoodistMac
git add appcast.xml
git commit -m "Update appcast for Beta 5 with signature"
git push origin main
```

### Paso 4: Crear Release en GitHub

1. Ve a https://github.com/jsgrrchg/MoodistMac/releases/new
2. **Tag**: `Beta-5` (debe coincidir con la URL en appcast)
3. **Title**: `Moodist 1.0 Beta 5`
4. **Description**: Puedes copiar el contenido de `CHANGELOG.md` sección Beta 5
5. **Attach binaries**: Sube `~/Desktop/MoodistMac.zip`
6. Haz clic en **Publish release**

## ✅ Verificación

Una vez completados todos los pasos:

- El zip está disponible en: `https://github.com/jsgrrchg/MoodistMac/releases/download/Beta-5/MoodistMac.zip`
- El appcast está actualizado en: `https://raw.githubusercontent.com/jsgrrchg/MoodistMac/main/appcast.xml`
- Los usuarios con la app instalada recibirán la actualización automáticamente al comprobar actualizaciones

## 🔧 Troubleshooting

### El script no encuentra sign_update

Si el path de `sign_update` cambió (por ejemplo, después de limpiar DerivedData), actualiza la variable `SIGN_UPDATE` en `scripts/prepare-release.sh` con el nuevo path. Puedes encontrarlo con:

```bash
find ~/Library/Developer/Xcode/DerivedData -name "sign_update" 2>/dev/null
```

### Error al firmar

Asegúrate de que el archivo de claves existe en `/Users/jfg/Desktop/MoodistMac-Sparkle-keys.txt` y contiene la clave privada.
