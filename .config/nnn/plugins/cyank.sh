#!/bin/sh
CLIP_DIR="${CLIP_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ish-clip}"
CLIP_FILES="${CLIP_FILES:-$CLIP_DIR/files.txt}"
NNN_SEL="${NNN_SEL:-${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.selection}"

mkdir -p "$CLIP_DIR"
: > "$CLIP_FILES"

if [ -f "$NNN_SEL" ]; then
  tr '\0' '\n' < "$NNN_SEL" | sed '/^$/d' > "$CL
