#!/bin/sh
# Empty trash
# Uses trash-cli: trash-empty [1](https://github.com/Mu-L/yazi-file-manager)

if ! command -v trash-empty >/dev/null 2>&1; then
  echo "missing trash-empty (install trash-cli)" >&2
  exit 1
fi

exec trash-empty
