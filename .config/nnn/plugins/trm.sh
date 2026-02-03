#!/bin/sh
# Remove items from trash permanently (interactive)
# Uses trash-cli: trash-rm [1](https://github.com/Mu-L/yazi-file-manager)

if ! command -v trash-rm >/dev/null 2>&1; then
  echo "missing trash-rm (install trash-cli)" >&2
  exit 1
fi

exec trash-rm
