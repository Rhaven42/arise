#!/usr/bin/env bash
# Allège les modèles générés par build_characters.py : textures en WebP puis
# géométrie quantifiée et compressée (EXT_meshopt_compression, décodée hors
# ligne par la visionneuse). Les noms des pièces, des formes et des
# animations sont conservés.
#
# Usage : tool/character/compress_models.sh <dossier des .glb bruts> assets/models
# Prérequis : npm install (dans tool/viewer) pour @gltf-transform/cli et sharp.
set -euo pipefail
src="$1"
dst="$2"
bin="$(dirname "$0")/../viewer/node_modules/.bin/gltf-transform"
tmp="$(mktemp -d)"
for file in "$src"/*.glb; do
  name="$(basename "$file")"
  node "$(dirname "$0")/../viewer/trim_clips.mjs" "$file" "$tmp/trim_$name"
  "$bin" webp "$tmp/trim_$name" "$tmp/$name" --quality 85
  "$bin" meshopt "$tmp/$name" "$dst/$name"
done
rm -rf "$tmp"
