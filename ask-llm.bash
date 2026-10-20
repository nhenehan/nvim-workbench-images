#!/usr/bin/env bash
# One-shot question to the local llama-server: ask-llm.bash "prompt..."
# Uses the chat endpoint so the model's chat template applies and it stops at end of turn.
LLM_URL="${LLM_URL:-http://localhost:${LLM_PORT:-9090}}"

jq -n --arg prompt "$*" \
    '{model: "local", messages: [{role: "user", content: $prompt}], max_tokens: 1024, temperature: 0.1}' |
    curl -s "$LLM_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d @- |
    jq -r '.choices[0].message.content'
