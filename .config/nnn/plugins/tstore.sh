#!/bin/sh
# Restore from trash (interactive)
# Uses trash-cli: trash-restore [1](https://github.com/Mu-L/yazi-file-manager)

if ! command -v trash-restore >/dev/null 2>&1; then
  echo "missing trash-restore (install trash-cli)" >&2
  exit 1
fi

exec trash-restore
