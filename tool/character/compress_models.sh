#!/usr/bin/env bash
# Allège les modèles générés par build_characters.py : textures en WebP puis
# géométrie quantifiée et compressée (EXT_meshopt_compression, décodée hors
# ligne par la visionneuse). Les noms des pièces, des formes et des
# animations sont conservés. Les tenues (<bruts>/outfits/<tenue>/*.glb) vont
# dans assets/outfits/<tenue>/ si un troisième dossier est donné.
#
# Usage : tool/character/compress_models.sh <dossier des .glb bruts> assets/models [assets/outfits]
# Prérequis : npm install (dans tool/viewer) pour @gltf-transform/cli et sharp.
set -euo pipefail
src="$1"
dst="$2"
outfits="${3:-}"
bin="$(dirname "$0")/../viewer/node_modules/.bin/gltf-transform"
tmp="$(mktemp -d)"
for file in "$src"/*.glb; do
  name="$(basename "$file")"
  node "$(dirname "$0")/../viewer/trim_clips.mjs" "$file" "$tmp/trim_$name"
  "$bin" webp "$tmp/trim_$name" "$tmp/$name" --quality 85
  "$bin" meshopt "$tmp/$name" "$dst/$name"
done
if [ -n "$outfits" ] && [ -d "$src/outfits" ]; then
  for dir in "$src"/outfits/*/; do
    set_id="$(basename "$dir")"
    mkdir -p "$outfits/$set_id"
    for file in "$dir"*.glb; do
      name="$(basename "$file")"
      "$bin" webp "$file" "$tmp/${set_id}_$name" --quality 85
      "$bin" meshopt "$tmp/${set_id}_$name" "$outfits/$set_id/$name"
    done
  done
fi
rm -rf "$tmp"
