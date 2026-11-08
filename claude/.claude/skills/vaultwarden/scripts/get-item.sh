#!/usr/bin/env bash
# Read a Vaultwarden item via rbw, which keeps the unlock cached in its agent so
# scripts do not need a session token. Writes go through add-item.sh and bw.
#
# rbw prints an item without a trailing newline. A `while read` loop over that
# output silently drops the last line, so this script always terminates output
# with one. That bug is easy to miss: the run looks fine and one secret is gone.
#
# Nothing is printed except the requested value, so output can be captured into
# a variable without leaking anything else.
#
# Usage:
#   get-item.sh ITEM                # whole item body
#   get-item.sh ITEM --key KEY      # one value from a key=value body
#
# Bodies holding several secrets use key=value lines; comments start with #.
set -euo pipefail

item=""; key=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --key) key="$2"; shift 2;;
    -*) echo "unknown arg: $1" >&2; exit 2;;
    *) item="$1"; shift;;
  esac
done

[[ -n "$item" ]] || { echo "item name required" >&2; exit 2; }

command -v rbw >/dev/null 2>&1 || { echo "rbw not installed" >&2; exit 2; }

# The vault is only reachable over Tailscale. Without this check, rbw sync waits
# forever with its output discarded, so the script hangs without a message.
vault_url=$(rbw config show | grep -oE '"base_url": *"[^"]+"' | cut -d'"' -f4)
if ! curl -s -o /dev/null --max-time 5 "$vault_url/alive"; then
  echo "cannot reach $vault_url. Check Tailscale is up." >&2
  exit 1
fi

# Stale after about a month, and a stale read is worse than a slow one.
rbw sync >/dev/null 2>&1 || true

if ! body=$(rbw get "$item" 2>/dev/null); then
  echo "cannot read '$item'. Unlock with 'rbw unlock' in your own terminal, and check Tailscale is up." >&2
  exit 1
fi

if [[ -z "$key" ]]; then
  printf '%s\n' "$body"
  exit 0
fi

value=$(printf '%s\n' "$body" | awk -F= -v k="$key" '$1 == k { sub(/^[^=]*=/, ""); print; exit }')

[[ -n "$value" ]] || { echo "key '$key' not found in '$item'" >&2; exit 1; }

printf '%s\n' "$value"
