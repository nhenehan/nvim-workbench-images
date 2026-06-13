#!/bin/env bash

QUERY="$1"

echo "=== TAGS ==="
grep -i "$QUERY" tags | head -20

echo
echo "=== FILES ==="

rg -l "$QUERY" . \
  --glob '!target/*' \
  | head -10 \
  | while read FILE
do
    echo
    echo "--- $FILE ---"

    rg -n "$QUERY" "$FILE" \
      | head -20
done