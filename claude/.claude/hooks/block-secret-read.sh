#!/usr/bin/env bash
# PreToolUse hook (matcher: Read).
# Deny reading credential files so their contents never land in the transcript.
path=$(jq -r '.tool_input.file_path // empty')
if printf '%s' "$path" | grep -qiE '(secret|credential|\.pem$|\.key$|\.pfx$|\.p12$|id_rsa|(^|/)\.env)'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Reading a credential file prints secrets into the transcript. Load the value inside a Bash step into a shell variable without echoing it (e.g. VAR=$(grep '^Client Secret' file | cut -d: -f2 | xargs)), then reference \"$VAR\"."}}
JSON
fi
exit 0
