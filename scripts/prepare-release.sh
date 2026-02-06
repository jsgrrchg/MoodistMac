#!/bin/bash

# Script para preparar el release de MoodistMac Beta 5
# Uso: ./scripts/prepare-release.sh /ruta/al/MoodistMac.app

set -e

SIGN_UPDATE="/Users/jfg/Library/Developer/Xcode/DerivedData/Moodist-gxmpoxmrffouvffcdablskaakoyd/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
KEYS_FILE="/Users/jfg/Desktop/MoodistMac-Sparkle-keys.txt"
DESKTOP_ZIP="$HOME/Desktop/MoodistMac.zip"

if [ $# -eq 0 ]; then
    echo "Error: Debes proporcionar la ruta al MoodistMac.app exportado"
    echo "Uso: $0 /ruta/al/MoodistMac.app"
    echo ""
    echo "Pasos previos:"
    echo "1. En Xcode: Product → Archive"
    echo "2. En el Organizer: Distribute App → Copy App"
    echo "3. Exporta a una carpeta y copia la ruta completa del .app"
    exit 1
fi

APP_PATH="$1"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: No se encontró el directorio: $APP_PATH"
    exit 1
fi

if [ ! -f "$KEYS_FILE" ]; then
    echo "Error: No se encontró el archivo de claves: $KEYS_FILE"
    exit 1
fi

if [ ! -f "$SIGN_UPDATE" ]; then
    echo "Error: No se encontró sign_update en: $SIGN_UPDATE"
    echo "Asegúrate de haber compilado el proyecto al menos una vez en Xcode"
    exit 1
fi

echo "=== Preparando release MoodistMac Beta 5 ==="
echo ""

# Extraer la clave privada del archivo de claves
PRIVATE_KEY=$(grep -A 1 "Clave PRIVADA" "$KEYS_FILE" | tail -1 | sed 's/^[[:space:]]*//')

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: No se pudo extraer la clave privada del archivo de claves"
    exit 1
fi

# Crear el zip en el escritorio
echo "1. Creando zip en el escritorio..."
if [ -f "$DESKTOP_ZIP" ]; then
    echo "   Advertencia: $DESKTOP_ZIP ya existe. Se sobrescribirá."
    rm -f "$DESKTOP_ZIP"
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$DESKTOP_ZIP"

if [ ! -f "$DESKTOP_ZIP" ]; then
    echo "Error: No se pudo crear el zip"
    exit 1
fi

ZIP_SIZE=$(stat -f%z "$DESKTOP_ZIP")
echo "   ✓ Zip creado: $DESKTOP_ZIP"
echo "   ✓ Tamaño: $ZIP_SIZE bytes"
echo ""

# Crear archivo temporal con la clave privada
TEMP_KEY_FILE=$(mktemp)
echo "$PRIVATE_KEY" > "$TEMP_KEY_FILE"

# Firmar el zip
echo "2. Firmando el zip con Sparkle..."
SIGNATURE_OUTPUT=$("$SIGN_UPDATE" --ed-key-file "$TEMP_KEY_FILE" "$DESKTOP_ZIP")

# Limpiar archivo temporal
rm -f "$TEMP_KEY_FILE"

if [ -z "$SIGNATURE_OUTPUT" ]; then
    echo "Error: No se pudo generar la firma"
    exit 1
fi

echo "   ✓ Firma generada"
echo ""

# Extraer edSignature y length de la salida
ED_SIGNATURE=$(echo "$SIGNATURE_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | sed 's/sparkle:edSignature="\([^"]*\)"/\1/')
LENGTH=$(echo "$SIGNATURE_OUTPUT" | grep -o 'length="[^"]*"' | sed 's/length="\([^"]*\)"/\1/')

if [ -z "$ED_SIGNATURE" ] || [ -z "$LENGTH" ]; then
    echo "Error: No se pudieron extraer la firma o el tamaño de la salida"
    echo "Salida completa:"
    echo "$SIGNATURE_OUTPUT"
    exit 1
fi

echo "   ✓ Firma extraída: ${ED_SIGNATURE:0:50}..."
echo "   ✓ Tamaño: $LENGTH bytes"
echo ""

# Actualizar appcast.xml automáticamente
APPCAST_FILE="appcast.xml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APPCAST_PATH="$PROJECT_ROOT/$APPCAST_FILE"

if [ -f "$APPCAST_PATH" ]; then
    echo "3. Actualizando appcast.xml..."
    cd "$PROJECT_ROOT"
    sed -i '' "s|sparkle:edSignature=\"PLACEHOLDER_REPLACE_WITH_SIGN_UPDATE_OUTPUT\"|sparkle:edSignature=\"$ED_SIGNATURE\"|g" "$APPCAST_FILE"
    sed -i '' "s|length=\"PLACEHOLDER_REPLACE_WITH_FILE_SIZE\"|length=\"$LENGTH\"|g" "$APPCAST_FILE"
    echo "   ✓ appcast.xml actualizado"
    echo ""
else
    echo "Advertencia: No se encontró appcast.xml en $APPCAST_PATH"
    echo "Actualiza manualmente con:"
    echo "  sparkle:edSignature=\"$ED_SIGNATURE\""
    echo "  length=\"$LENGTH\""
    echo ""
fi

echo "=== Próximos pasos ==="
echo ""
echo "1. Haz commit y push del appcast actualizado:"
echo "   cd $PROJECT_ROOT"
echo "   git add appcast.xml"
echo "   git commit -m 'Update appcast for Beta 5 with signature'"
echo "   git push origin main"
echo ""
echo "2. Ve a GitHub y crea un nuevo Release:"
echo "   - Tag: Beta-5"
echo "   - Sube el archivo: $DESKTOP_ZIP"
echo "   - Descripción: Puedes usar el CHANGELOG.md"
echo ""
echo "¡Listo! Los usuarios recibirán la actualización automáticamente."
