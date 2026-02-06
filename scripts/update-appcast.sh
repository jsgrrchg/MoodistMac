#!/bin/bash

# Script para actualizar appcast.xml con la firma y tamaño del zip
# Uso: ./scripts/update-appcast.sh <edSignature> <length>

set -e

APPCAST_FILE="appcast.xml"

if [ $# -ne 2 ]; then
    echo "Error: Debes proporcionar la firma y el tamaño"
    echo "Uso: $0 <edSignature> <length>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 'RKaxGCEZyyUJ8GudiTASMY53W455lJ4j8fqtJGYmkfaula5/FzVHuqnSDeMtQc+dEESdRbEWCV/aAyfxaGYMBQ==' '122141859'"
    exit 1
fi

ED_SIGNATURE="$1"
LENGTH="$2"

if [ ! -f "$APPCAST_FILE" ]; then
    echo "Error: No se encontró $APPCAST_FILE"
    exit 1
fi

# Actualizar los placeholders en el appcast
sed -i '' "s|sparkle:edSignature=\"PLACEHOLDER_REPLACE_WITH_SIGN_UPDATE_OUTPUT\"|sparkle:edSignature=\"$ED_SIGNATURE\"|g" "$APPCAST_FILE"
sed -i '' "s|length=\"PLACEHOLDER_REPLACE_WITH_FILE_SIZE\"|length=\"$LENGTH\"|g" "$APPCAST_FILE"

echo "✓ appcast.xml actualizado con:"
echo "  sparkle:edSignature=\"$ED_SIGNATURE\""
echo "  length=\"$LENGTH\""
echo ""
echo "Ahora puedes hacer commit y push:"
echo "  git add appcast.xml"
echo "  git commit -m 'Update appcast for Beta 5 with signature'"
echo "  git push origin main"
