#!/bin/sh -e

dhall_haskell="$(eval echo "$DHALL_BINARY")"
archive=$(mktemp)
curl -Lsf "$dhall_haskell" -o "$archive"
tar -xjf "$archive"
PATH="$(pwd)/bin:$PATH"

echo "::add-matcher::$GITHUB_ACTION_PATH/dhall-checker.json"

export DHALL_FAILURES=$(mktemp -d)
if [ -z "$LIST" ]; then
  export LIST=$(mktemp)
fi
if [ -n "$FILES" ]; then
  echo "$FILES" | tr "\n" "\0" >> $LIST
fi
if [ -z "$PARALLEL_JOBS" ]; then
  PARALLEL_JOBS=2
fi
cat $LIST |
  xargs -0 "-P$PARALLEL_JOBS" -r -n1 $GITHUB_ACTION_PATH/dhall-checker
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
