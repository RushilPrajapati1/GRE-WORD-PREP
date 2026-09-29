#!/bin/sh
# Prints the UDID of the preferred iPhone simulator (newest runtime wins).
# Falls back to any available iPhone if the preferred model isn't installed.
NAME="${1:-iPhone 16}"
DEVICES=$(xcrun simctl list devices available)
ID=$(printf '%s\n' "$DEVICES" | grep -E "^[[:space:]]+$NAME \(" | tail -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
if [ -z "$ID" ]; then
  ID=$(printf '%s\n' "$DEVICES" | grep -E "^[[:space:]]+iPhone" | tail -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
fi
if [ -z "$ID" ]; then
  echo "No available iPhone simulator found (see: xcrun simctl list devices)" >&2
  exit 1
fi
echo "$ID"
