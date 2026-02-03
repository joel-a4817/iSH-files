###############################################################################
# iSH ~/.profile — nnn + lazygit + trash + clipboard + yank/paste + trash tools
###############################################################################

# ---------- Basic QoL ----------
export TERM="${TERM:-xterm-256color}"

###############################################################################
# nnn configuration (env var based; no config file) [3](https://github.com/ish-app/ish/issues/2570)[2](https://github.com/ish-app/ish.app/blob/master/_posts/2021-04-26-default-repository-update.md)
###############################################################################

# Where nnn stores selected files (NULL-separated list by default).
export NNN_SEL="${NNN_SEL:-${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.selection}"

# Plugin directory
NNN_PLUGDIR="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins"
mkdir -p "$NNN_PLUGDIR"

# ---------- Trash integration ----------
# nnn supports trash via gio trash / trash-cli; default is rm -rf. [3](https://github.com/ish-app/ish/issues/2570)[2](https://github.com/ish-app/ish.app/blob/master/_posts/2021-04-26-default-repository-update.md)
# We enable NNN_TRASH only if we detect trash-cli commands.
if command -v trash-put >/dev/null 2>&1 || command -v trash >/dev/null 2>&1; then
  export NNN_TRASH=1
else
  unset NNN_TRASH
fi

# ---------- Plugin keybinds via NNN_PLUG ----------
# nnn plugins are executable scripts; key mappings are set in NNN_PLUG. [5](https://ish.app/blog/default-repository-update)[3](https://github.com/ish-app/ish/issues/2570)
#
# Keys:
#   g = lazygit
#   y = clip yank (from nnn selection)
#   p = clip paste (paste yanked files into cwd)
#   T = trash list UI
#   R = trash restore UI
#   E = trash empty
#   D = trash delete (remove from trash permanently)
export NNN_PLUG='g:lazyg.sh;y:cyank.sh;p:cpaste.sh;T:tlist.sh;R:trestore.sh;E:tempty.sh;D:trm.sh'

###############################################################################
# Makeshift clipboard (text + file clipboard) for iSH
###############################################################################

# Clipboard storage
export CLIP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ish-clip"
export CLIP_HIST="$CLIP_DIR/history.txt"
export CLIP_LAST="$CLIP_DIR/last.txt"
export CLIP_PINS="$CLIP_DIR/pins.txt"

# File “clipboard” (paths yanked from nnn selection)
export CLIP_FILES="$CLIP_DIR/files.txt"

mkdir -p "$CLIP_DIR"
touch "$CLIP_HIST" "$CLIP_LAST" "$CLIP_PINS" "$CLIP_FILES"

# Normalize CRLF -> LF
_clip_norm() { sed 's/\r$//'; }

# -------- TEXT clipboard core --------
clip_add() {
  if [ "$#" -gt 0 ]; then
    printf "%s\n" "$*" | _clip_norm | tee "$CLIP_LAST" >> "$CLIP_HIST" >/dev/null
  else
    _clip_norm | tee "$CLIP_LAST" >> "$CLIP_HIST" >/dev/null
  fi
}

clip_addf() {
  [ -f "$1" ] || { echo "clip addf: file not found: $1" >&2; return 1; }
  cat "$1" | clip_add
}

clip_last() { cat "$CLIP_LAST"; }
clip_list() { nl -ba "$CLIP_HIST"; }

clip_clear() {
  : > "$CLIP_HIST"
  : > "$CLIP_LAST"
  echo "clipboard cleared"
}

clip_clearall() {
  : > "$CLIP_HIST"
  : > "$CLIP_LAST"
  : > "$CLIP_PINS"
  : > "$CLIP_FILES"
  echo "clipboard + pins + files cleared"
}

clip_pin() {
  if [ "$#" -gt 0 ]; then
    printf "%s\n" "$*" | _clip_norm >> "$CLIP_PINS"
    printf "%s\n" "$*" | _clip_norm > "$CLIP_LAST"
  else
    cat "$CLIP_LAST" >> "$CLIP_PINS"
  fi
  echo "pinned"
}

clip_pins() { nl -ba "$CLIP_PINS"; }

clip_unpin() {
  n="$1"
  [ -n "$n" ] || { echo "usage: clip unpin <line#>" >&2; return 1; }
  awk -v n="$n" 'NR!=n' "$CLIP_PINS" > "$CLIP_PINS.tmp" && mv "$CLIP_PINS.tmp" "$CLIP_PINS"
}

clip_pick() {
  if command -v fzf >/dev/null 2>&1; then
    {
      [ -s "$CLIP_PINS" ] && sed 's/^/[PIN] /' "$CLIP_PINS"
      sed 's/^/[HIS] /' "$CLIP_HIST"
    } | fzf --tac --no-sort --prompt="clip> " --height=60% \
      | sed 's/^\[[A-Z]*\] //' | tee "$CLIP_LAST"
  else
    echo "fzf not installed. Tip: apk add fzf" >&2
    return 1
  fi
}

clip_pickm() {
  if command -v fzf >/dev/null 2>&1; then
    {
      [ -s "$CLIP_PINS" ] && sed 's/^/[PIN] /' "$CLIP_PINS"
      sed 's/^/[HIS] /' "$CLIP_HIST"
    } | fzf --tac --no-sort --multi --prompt="clip(multi)> " --height=60% \
      | sed 's/^\[[A-Z]*\] //' | tee "$CLIP_LAST"
  else
    echo "fzf not installed. Tip: apk add fzf" >&2
    return 1
  fi
}

clip_del() {
  n="$1"
  [ -n "$n" ] || { echo "usage: clip del <line#>" >&2; return 1; }
  awk -v n="$n" 'NR!=n' "$CLIP_HIST" > "$CLIP_HIST.tmp" && mv "$CLIP_HIST.tmp" "$CLIP_HIST"
}

paste() { clip_last; }

# BONUS: copy command output into clipboard + print it
copy() {
  if [ "$#" -eq 0 ]; then
    echo "usage: copy <command...>" >&2
    return 1
  fi
  "$@" 2>&1 | clip_add
  cat "$CLIP_LAST"
}

# BONUS: tee stdin into clipboard (for pipelines)
ctee() {
  _clip_norm | tee "$CLIP_LAST" >> "$CLIP_HIST"
}

clip_edit() {
  : "${EDITOR:=vi}"
  "$EDITOR" "$CLIP_LAST"
  cat "$CLIP_LAST" | clip_add
}

# -------- FILE clipboard (nnn yank/paste) --------

# Turn nnn selection file into a newline list (handles NULL-separated selection)
_nnn_sel_to_lines() {
  sel="${NNN_SEL:-${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.selection}"
  [ -f "$sel" ] || return 1
  tr '\0' '\n' < "$sel" | sed '/^$/d'
}

# clip yank: grab nnn selection into CLIP_FILES
clip_yank() {
  if _nnn_sel_to_lines > "$CLIP_FILES"; then
    count=$(wc -l < "$CLIP_FILES" | tr -d ' ')
    echo "yanked $count path(s) into file clipboard"
    return 0
  fi
  echo "clip yank: no selection file or nothing selected (NNN_SEL=$NNN_SEL)" >&2
  return 1
}

# clip files: show yanked paths
clip_files() {
  if [ -s "$CLIP_FILES" ]; then
    nl -ba "$CLIP_FILES"
  else
    echo "(file clipboard empty) — run: clip yank" >&2
    return 1
  fi
}

# Internal: robust copy function (directories included)
_clip_cp_one() {
  src="$1"; dst="$2"; overwrite="$3"
  base="$(basename "$src")"
  target="$dst/$base"

  if [ -e "$target" ] && [ "$overwrite" != "1" ]; then
    echo "skip: exists: $target" >&2
    return 0
  fi

  if [ -e "$target" ] && [ "$overwrite" = "1" ]; then
    rm -rf "$target"
  fi

  if [ -d "$src" ]; then
    cp -R "$src" "$dst/"
  else
    cp "$src" "$dst/"
  fi
}

# clip paste: copy/move yanked files into current directory (or dest dir)
clip_paste() {
  overwrite=0
  move=0
  dest=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --overwrite|-f) overwrite=1;;
      --move|-m) move=1;;
      *) dest="$1";;
    esac
    shift
  done

  [ -n "$dest" ] || dest="$PWD"
  [ -d "$dest" ] || { echo "clip paste: dest not a directory: $dest" >&2; return 1; }
  [ -s "$CLIP_FILES" ] || { echo "clip paste: file clipboard empty — run: clip yank" >&2; return 1; }

  while IFS= read -r src; do
    [ -e "$src" ] || { echo "missing: $src" >&2; continue; }

    if [ "$move" = "1" ]; then
      base="$(basename "$src")"
      target="$dest/$base"
      if [ -e "$target" ] && [ "$overwrite" != "1" ]; then
        echo "skip(move): exists: $target" >&2
        continue
      fi
      [ -e "$target" ] && [ "$overwrite" = "1" ] && rm -rf "$target"
      mv "$src" "$dest/"
    else
      _clip_cp_one "$src" "$dest" "$overwrite"
    fi
  done < "$CLIP_FILES"

  echo "paste done -> $dest"
}

# -------- TRASH helpers (Yazi-like trash-cli tools) --------
# Yazi recycle-bin uses: trash-list, trash-empty, trash-restore, trash-rm [4](https://github.com/Mu-L/yazi-file-manager)
trash_ok() {
  command -v trash-list >/dev/null 2>&1 && \
  command -v trash-restore >/dev/null 2>&1 && \
  command -v trash-empty >/dev/null 2>&1 && \
  command -v trash-rm >/dev/null 2>&1
}

trash_list() {
  command -v trash-list >/dev/null 2>&1 || { echo "missing trash-list (install trash-cli)"; return 1; }
  trash-list
}

trash_restore() {
  command -v trash-restore >/dev/null 2>&1 || { echo "missing trash-restore (install trash-cli)"; return 1; }
  trash-restore
}

trash_empty() {
  command -v trash-empty >/dev/null 2>&1 || { echo "missing trash-empty (install trash-cli)"; return 1; }
  trash-empty
}

trash_rm() {
  command -v trash-rm >/dev/null 2>&1 || { echo "missing trash-rm (install trash-cli)"; return 1; }
  trash-rm "$@"
}

# main dispatcher
clip() {
  sub="${1:-help}"
  shift || true
  case "$sub" in
    add)       clip_add "$@";;
    addf)      clip_addf "$@";;
    last)      clip_last;;
    list)      clip_list;;
    pick)      clip_pick;;
    pickm)     clip_pickm;;
    del)       clip_del "$@";;
    clear)     clip_clear;;
    clearall)  clip_clearall;;
    pin)       clip_pin "$@";;
    pins)      clip_pins;;
    unpin)     clip_unpin "$@";;
    edit)      clip_edit;;

    yank)      clip_yank;;
    files)     clip_files;;
    paste)     clip_paste "$@";;

    trash-list)    trash_list;;
    trash-restore) trash_restore;;
    trash-empty)   trash_empty;;
    trash-rm)      trash_rm "$@";;

    help|*)
      cat <<'EOF'
clip: makeshift clipboard for iSH (text + file clipboard) + trash helpers

TEXT:
  clip add "text"         Add text (or pipe stdin) to clipboard history
  clip addf FILE          Add file contents
  clip last               Show last entry
  clip list               Show numbered history
  clip pick               Fuzzy-pick one entry (needs fzf)
  clip pickm              Fuzzy multi-pick into last (needs fzf)
  clip del N              Delete history line N
  clip clear              Clear history + last
  clip clearall           Clear history + last + pins + files
  clip pin [text]         Pin last entry (or provided text)
  clip pins               List pins
  clip unpin N            Remove pinned line N
  clip edit               Edit last entry in $EDITOR and re-save
  paste                   Print last entry
  copy <cmd...>           Run command, save output to clipboard, print it
  ctee                    Tee stdin into clipboard (for pipelines)

FILES (nnn selection):
  clip yank               Yank nnn selection (NNN_SEL) into file clipboard
  clip files              Show yanked file list
  clip paste [dir]        Copy yanked files into dir (default: $PWD)
  clip paste --overwrite  Overwrite existing targets
  clip paste --move       Move instead of copy

TRASH (trash-cli like Yazi recycle-bin):
  clip trash-list         List trash items
  clip trash-restore      Interactive restore (trash-restore)
  clip trash-empty        Empty trash (trash-empty)
  clip trash-rm [args]    Remove from trash (trash-rm)

Notes:
- nnn trash support uses trash-cli/gio trash when enabled; default delete is rm -rf. [3](https://github.com/ish-app/ish/issues/2570)[2](https://github.com/ish-app/ish.app/blob/master/_posts/2021-04-26-default-repository-update.md)
- nnn subshell: press '!' inside nnn to spawn a shell in the current directory. [1](https://saipien.org/four-terminal-file-managers-for-linux-mc-ranger-nnn-and-yazi-for-ssh-containers-automation/)[2](https://github.com/ish-app/ish.app/blob/master/_posts/2021-04-26-default-repository-update.md)
EOF
      ;;
  esac
}

###############################################################################
# nnn plugin scripts (lazygit + yank/paste + trash UI plugins)
###############################################################################
# nnn plugins are executable scripts in the plugins directory. [5](https://ish.app/blog/default-repository-update)

# lazygit plugin (keybound via NNN_PLUG)
if [ ! -x "$NNN_PLUGDIR/lazyg.sh" ]; then
  cat > "$NNN_PLUGDIR/lazyg.sh" <<'EOF'
#!/bin/sh
exec lazygit
EOF
  chmod +x "$NNN_PLUGDIR/lazyg.sh"
fi

# cyank: yank selection into file clipboard from inside nnn
if [ ! -x "$NNN_PLUGDIR/cyank.sh" ]; then
  cat > "$NNN_PLUGDIR/cyank.sh" <<'EOF'
#!/bin/sh
CLIP_DIR="${CLIP_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/ish-clip}"
CLIP_FILES="${CLIP_FILES:-$CLIP_DIR/files.txt}"
NNN_SEL="${NNN_SEL:-${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.selection}"

mkdir -p "$CLIP_DIR"
: > "$CLIP_FILES"

if [ -f "$NNN_SEL" ]; then
  tr '\0' '\n' < "$NNN_SEL" | sed '/^$/d' > "$CLIP_FILES"
  n=$(wc -l < "$CLIP_FILES" | tr -d ' ')
  echo "yanked $n path(s)"
else
  echo "no selection (NNN_SEL=$NNN_SEL)" >&2
  exit 1
fi
EOF
  chmod +x "$NNN_PLUGDIR/cyank.sh"
fi

# cpaste: paste yanked files into the current directory from inside nnn
if [ ! -x "$NNN_PLUGDIR/cpaste.sh" ]; then
  cat > "$NNN_PLUGDIR/cpaste.sh" <<'EOF'
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
EOF
  chmod +x "$NNN_PLUGDIR/cpaste.sh"
fi

# tlist: show trash list (optionally with fzf preview)
if [ ! -x "$NNN_PLUGDIR/tlist.sh" ]; then
  cat > "$NNN_PLUGDIR/tlist.sh" <<'EOF'
#!/bin/sh
if ! command -v trash-list >/dev/null 2>&1; then
  echo "missing trash-list (install trash-cli)" >&2
  exit 1
fi
trash-list | ${PAGER:-less}
EOF
  chmod +x "$NNN_PLUGDIR/tlist.sh"
fi

# trestore: interactive restore (trash-restore is already interactive)
if [ ! -x "$NNN_PLUGDIR/trestore.sh" ]; then
  cat > "$NNN_PLUGDIR/trestore.sh" <<'EOF'
#!/bin/sh
if ! command -v trash-restore >/dev/null 2>&1; then
  echo "missing trash-restore (install trash-cli)" >&2
  exit 1
fi
exec trash-restore
EOF
  chmod +x "$NNN_PLUGDIR/trestore.sh"
fi

# tempty: empty trash
if [ ! -x "$NNN_PLUGDIR/tempty.sh" ]; then
  cat > "$NNN_PLUGDIR/tempty.sh" <<'EOF'
#!/bin/sh
if ! command -v trash-empty >/dev/null 2>&1; then
  echo "missing trash-empty (install trash-cli)" >&2
  exit 1
fi
exec trash-empty
EOF
  chmod +x "$NNN_PLUGDIR/tempty.sh"
fi

# trm: remove from trash permanently (prompt via trash-rm)
if [ ! -x "$NNN_PLUGDIR/trm.sh" ]; then
  cat > "$NNN_PLUGDIR/trm.sh" <<'EOF'
#!/bin/sh
if ! command -v trash-rm >/dev/null 2>&1; then
  echo "missing trash-rm (install trash-cli)" >&2
  exit 1
fi
# trash-rm prompts for what to remove
exec trash-rm
EOF
  chmod +x "$NNN_PLUGDIR/trm.sh"
fi

###############################################################################
# End of ~/.profile
###############################################################################
