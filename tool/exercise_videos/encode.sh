#!/usr/bin/env bash
# Convertit une vidéo rendue (MP4) en WebP animé en boucle pour l'application,
# avec sa première image fixe (pause, animations réduites).
#
# Usage : tool/exercise_videos/encode.sh <vidéo.mp4> <identifiant d'exercice>
set -euo pipefail
src="$1"
id="$2"
out="assets/exercise_videos"
mkdir -p "$out"
ffmpeg -y -loglevel error -i "$src" -vf "scale=540:-2,fps=24" -loop 0 \
  -c:v libwebp_anim -quality 72 -compression_level 6 -preset picture "$out/$id.webp"
ffmpeg -y -loglevel error -i "$src" -vf "scale=540:-2" -frames:v 1 \
  -c:v libwebp -quality 80 "$out/${id}_still.webp"
echo "$out/$id.webp $(du -h "$out/$id.webp" | cut -f1)"
