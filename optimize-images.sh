#!/usr/bin/env bash
# optimize-images.sh
# Génère des variantes optimisées (WebP + JPEG) pour les images sources listées.
# Usage: ./optimize-images.sh
# Requis: cwebp (libwebp) et imagemagick (convert/magick) ou uniquement imagemagick.

set -euo pipefail

# Configuration
IMAGES=("DSC03430.jpg" "DSC03437.jpg" "DSC03489.jpg")
SIZES=(400 800 1600)
WEBP_QUALITY=80
JPEG_QUALITY=85
OUT_DIR="." # ou "images" si vous préférez

command_exists(){ command -v "$1" >/dev/null 2>&1; }

echo "Vérification des outils..."
if command_exists cwebp; then
  TOOL_WEBP="cwebp"
elif command_exists magick || command_exists convert; then
  TOOL_WEBP="magick" # ImageMagick fera la conversion vers WebP si supporté
else
  echo "ERREUR: Aucun outil de conversion trouvé. Installez 'cwebp' ou 'imagemagick'." >&2
  exit 1
fi

for img in "${IMAGES[@]}"; do
  if [ ! -f "$img" ]; then
    echo "Attention: fichier source non trouvé: $img — saute." >&2
    continue
  fi
  base="${img%.*}"
  ext="${img##*.}"
  for size in "${SIZES[@]}"; do
    out_jpeg="$OUT_DIR/${base}-${size}.jpg"
    out_webp="$OUT_DIR/${base}-${size}.webp"

    echo "Traitement $img → ${size}px → $out_jpeg + $out_webp"

    # Redimensionner puis exporter JPEG via ImageMagick (si disponible)
    if command_exists magick; then
      magick "$img" -resize ${size}x -quality ${JPEG_QUALITY} "$out_jpeg"
    elif command_exists convert; then
      convert "$img" -resize ${size}x -quality ${JPEG_QUALITY} "$out_jpeg"
    else
      echo "ImageMagick non trouvé pour créer JPEG, saut de $out_jpeg" >&2
    fi

    # Générer WebP
    if [ "$TOOL_WEBP" = "cwebp" ]; then
      # Utiliser cwebp à partir du JPEG redimensionné si disponible
      if [ -f "$out_jpeg" ]; then
        cwebp -q ${WEBP_QUALITY} "$out_jpeg" -o "$out_webp" >/dev/null
      else
        # fallback: convertir directement depuis l'original
        cwebp -resize ${size} 0 -q ${WEBP_QUALITY} "$img" -o "$out_webp" >/dev/null || echo "Échec conversion WebP pour $img" >&2
      fi
    else
      # ImageMagick (magick) pour exporter WebP
      if command_exists magick; then
        magick "$img" -resize ${size}x -quality ${WEBP_QUALITY} "$out_webp"
      elif command_exists convert; then
        convert "$img" -resize ${size}x -quality ${WEBP_QUALITY} "$out_webp"
      fi
    fi

    # Vérification rapide
    if [ -f "$out_webp" ]; then
      echo "→ $out_webp créé"
    else
      echo "! webp non créé pour $img at $size" >&2
    fi
    if [ -f "$out_jpeg" ]; then
      echo "→ $out_jpeg créé"
    fi
  done
done

echo "Optimisation terminée. N'oubliez pas de committer les fichiers générés (git add ...) si satisfaits." 
