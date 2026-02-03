#!/bin/sh
# List trash contents (Yazi-like "browse trash")
# Uses trash-cli: trash-list [1](https://github.com/Mu-L/yazi-file-manager)

if ! command -v trash-list >/dev/null 2>&1; then
  echo "missing trash-list (install trash-cli)" >&2
  exit 1
fi

trash-list | ${PAGER:-less}
