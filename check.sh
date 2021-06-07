#!/bin/sh

command -v "parallel" >/dev/null 2>/dev/null || (
  apt update
  apt install -y parallel
)
dhall_haskell="$(eval echo "$DHALL_BINARY")"
curl -Ls $dhall_haskell | tar -xjf -
PATH="$(pwd)/bin:$PATH"

echo "::add-matcher::dhall-checker.json"

export DHALL_FAILURES=$(mktemp -d)
if [ -z "$LIST" ]; then
  export LIST=$(mktemp)
fi
if [ -n "$FILES" ]; then
  echo "$FILES" | tr "\n" "\0" >> $LIST
fi
cat $LIST |
  parallel -0 --no-notice --no-run-if-empty -n1 $GITHUB_ACTION_PATH/dhall-checker
(
  cd $DHALL_FAILURES
  files="$(find . -type f)"
  if [ -z "$files" ]; then
    exit 0
  fi
  echo
  echo "Errors detected in:"
  for file in $files; do cat $file; done
  exit 1
)
