#!/bin/env bash

PROMPT="$*"

curl -s \
    http://localhost:8080/completion \
    -H "Content-Type: application/json" \
    -d @- <<EOF |
{
  "prompt": "$PROMPT",
  "n_predict": 512,
  "temperature": 0.1
}
EOF
jq -r '.content'