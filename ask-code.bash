#!/bin/env bash

QUESTION="$*"

CONTEXT=$(
    ~/scripts/context.sh "$QUESTION"
)

PROMPT=$(cat <<EOF
You are a Rust software engineer.

Repository Context:

$CONTEXT

Question:

$QUESTION

Answer using only repository information when possible.
EOF
)

~/scripts/ask-llm "$PROMPT"