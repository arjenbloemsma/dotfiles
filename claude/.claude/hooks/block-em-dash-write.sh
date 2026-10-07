#!/usr/bin/env bash
# PreToolUse hook (matcher: Write|Edit).
# Deny writes that would put an em-dash in a file.
# Only the text being written. old_string is skipped so an em-dash can be edited out.
text=$(jq -r '[.tool_input.content, .tool_input.new_string] | map(select(. != null)) | join("\n")')
if printf '%s' "$text" | grep -q '—'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Em-dash detected. Rewrite with a period, comma, colon, or parentheses."}}
JSON
fi
exit 0
