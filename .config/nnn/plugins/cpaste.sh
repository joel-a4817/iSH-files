#!/bin/sh
CLIP_DIR="${CLIP_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ish-clip}"
CLIP_FILES="${CLIP_FILES:-$CLIP_DIR/files.txt}"
mkdir -p "$CLIP_DIR"

[ -s "$CLIP_FILES" ] || { echo "file clipboard empty" >&2; exit 1; }

dest="$PWD"

while IFS= read -r src; do
  [ -e "$src" ] || { echo "missing: $src" >&2; continue; }
  if [ -d "$src" ]; then
    cp -R "$src" "$dest/"
  else
    cp "$src" "$dest/"
  fi
done < "$CLIP_FILES"

echo "pasted into $dest"
