#!/usr/bin/env bash
# Assemble les images rendues par animate_coach.py en WebP animé en boucle,
# plus une image fixe (milieu du mouvement) pour la pause et les animations
# réduites.
#
# Usage : tool/coach/encode.sh <dossier des images> <monde> [mouvement ...]
set -euo pipefail
src="$1"
world="$2"
shift 2
out="assets/coach_videos/$world"
mkdir -p "$out"
ids=("$@")
if [ ${#ids[@]} -eq 0 ]; then
  mapfile -t ids < <(ls "$src" | sed -E 's/_[0-9]{3}\.png$//' | sort -u)
fi
for id in "${ids[@]}"; do
  frames=$(ls "$src"/"${id}"_[0-9][0-9][0-9].png | wc -l)
  ffmpeg -y -loglevel error -framerate 15 -i "$src/${id}_%03d.png" -loop 0 \
    -c:v libwebp_anim -quality 70 -compression_level 6 -preset picture "$out/$id.webp"
  mid=$(printf "%03d" $((frames / 2)))
  ffmpeg -y -loglevel error -i "$src/${id}_$mid.png" -c:v libwebp -quality 80 "$out/${id}_still.webp"
  echo "$out/$id.webp $(du -h "$out/$id.webp" | cut -f1)"
done
