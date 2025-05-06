#!/bin/sh

if [ $# -lt 1 ]; then
  echo "Usage: $0 <dir to scan>"
  exit 1
fi

DIR="$1"

ls -la "$DIR" | grep -i -e "ft\. " -e "feat" -e " & " # | grep -vF "(feat. "
