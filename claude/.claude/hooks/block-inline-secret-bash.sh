#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash).
# Deny commands passing a literal secret inline; require a shell variable instead.
cmd=$(jq -r '.tool_input.command // empty')
flag='--(password|client-secret|secret)[= ]'
safe='--(password|client-secret|secret)[= ]+"?\$'
if printf '%s' "$cmd" | grep -qiE -- "$flag" && ! printf '%s' "$cmd" | grep -qiE -- "$safe"; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Inline secret detected. Put the value in a shell variable and pass it as \"$VAR\" so it never appears in the command text or output."}}
JSON
fi
exit 0
