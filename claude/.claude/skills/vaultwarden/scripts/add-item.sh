#!/usr/bin/env bash
# Create a single Vaultwarden item via the Bitwarden CLI without ever placing
# the secret value on a command line (argv is world-readable via `ps`).
#
# The secret value is read from the SECRET environment variable and injected
# into the item JSON by jq via `env.SECRET`, so it never appears in argv.
# Item metadata is passed via flags. Nothing secret is printed to stdout.
#
# Requires: bw configured to the Vaultwarden server, jq on PATH, and BW_SESSION
# read from the session file the user wrote in a separate terminal:
#   bw unlock --raw > <scratchpad>/bw-session
#   export BW_SESSION="$(cat <scratchpad>/bw-session)"
#
# Usage:
#   SECRET='the-secret' add-item.sh --name NAME [--type note|login] \
#       [--username USER] [--uri URI] [--folder FOLDER] [--note "context text"] \
#       [--yubikey 1] [--yubikey 2]
#
#   note  -> Secure Note; secret goes in the note body (default)
#   login -> Login item; secret is the password, --username and --uri optional
#   --yubikey N -> sets the Boolean field "yubikey N" (login only, repeatable)
set -euo pipefail

name=""; type="note"; username=""; uri=""; folder=""; note=""; yubikeys="[]"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) name="$2"; shift 2;;
    --type) type="$2"; shift 2;;
    --username) username="$2"; shift 2;;
    --uri) uri="$2"; shift 2;;
    --folder) folder="$2"; shift 2;;
    --note) note="$2"; shift 2;;
    --yubikey)
      [[ "$2" == 1 || "$2" == 2 ]] || { echo "--yubikey must be 1 or 2" >&2; exit 2; }
      yubikeys=$(jq -c --arg n "yubikey $2" '. + [{name:$n, value:"true", type:2}]' <<<"$yubikeys")
      shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

[[ -n "$name" ]]              || { echo "--name required" >&2; exit 2; }
[[ "$yubikeys" == "[]" || "$type" == "login" ]] || { echo "--yubikey needs --type login" >&2; exit 2; }
[[ -n "${SECRET:-}" ]]        || { echo "SECRET env var required" >&2; exit 2; }
[[ -n "${BW_SESSION:-}" ]]    || { echo "BW_SESSION not set; ask the user to run 'bw unlock --raw > <scratchpad>/bw-session' in a separate terminal, then export BW_SESSION=\"\$(cat <scratchpad>/bw-session)\"" >&2; exit 2; }

# Resolve folder name -> id, creating the folder if it does not exist yet.
folderId="null"
if [[ -n "$folder" ]]; then
  fid=$(bw list folders --session "$BW_SESSION" \
        | jq -r --arg n "$folder" 'map(select(.name==$n)) | .[0].id // empty')
  if [[ -z "$fid" ]]; then
    fid=$(jq -n --arg n "$folder" '{name:$n}' \
          | bw encode | bw create folder --session "$BW_SESSION" | jq -r '.id')
  fi
  folderId="\"$fid\""
fi

# Build the item JSON. env.SECRET keeps the value out of argv.
if [[ "$type" == "login" ]]; then
  item=$(jq -n --arg name "$name" --arg user "$username" --arg uri "$uri" \
             --arg note "$note" --argjson folderId "$folderId" --argjson fields "$yubikeys" \
    '{type:1, name:$name, notes:(if $note=="" then null else $note end),
      folderId:$folderId, fields:$fields, login:{username:(if $user=="" then null else $user end),
      password:env.SECRET,
      uris:(if $uri=="" then null else [{match:null, uri:$uri}] end)}}')
else
  item=$(jq -n --arg name "$name" --arg note "$note" --argjson folderId "$folderId" \
    '{type:2, name:$name, folderId:$folderId, secureNote:{type:0},
      notes:(env.SECRET + (if $note=="" then "" else "\n\n---\n" + $note end))}')
fi

id=$(printf '%s' "$item" | bw encode | bw create item --session "$BW_SESSION" | jq -r '.id')
echo "created: $name  ($id)"
