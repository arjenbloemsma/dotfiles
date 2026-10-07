#!/usr/bin/env bash
# PreToolUse hook (matcher: Write|Edit).
# Deny writes that would put an em-dash in a file. The memory index format
# uses one as its separator, so that directory is exempt. old_string is not
# checked, so an em-dash can still be edited out.
# The dash is built from its bytes, so this file holds none itself.
dash=$(printf '\xe2\x80\x94')

verdict=$(jq -r --arg d "$dash" '
  if (.tool_input.file_path // "") | test("/\\.claude/projects/.*/memory/") then "ok"
  elif [.tool_input.content, .tool_input.new_string] | map(select(.)) | join("\n") | contains($d) then "deny"
  else "ok" end')

if [ "$verdict" = deny ]; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Em-dash detected. Rewrite with a period, comma, colon, or parentheses."}}
JSON
fi
exit 0
