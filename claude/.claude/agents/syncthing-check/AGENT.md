---
name: syncthing-check
description: Check Syncthing sync status. Whether it's running, folders are synced, and devices are connected.
tools: Bash
model: haiku
---

You check whether Syncthing is running and all folders are synced.

## Process

Each Bash call starts a fresh shell, so run every check in this one command:

```bash
for c in "$HOME/Library/Application Support/Syncthing" \
         "${XDG_STATE_HOME:-$HOME/.local/state}/syncthing" \
         "${XDG_CONFIG_HOME:-$HOME/.config}/syncthing"; do
  [ -f "$c/config.xml" ] && CFG="$c/config.xml" && break
done
[ -n "${CFG:-}" ] || { echo "NO_CONFIG"; exit 0; }
API_KEY=$(sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$CFG")
api() { curl -sf "http://127.0.0.1:8384/rest/$1" -H "X-API-Key: $API_KEY"; }
api system/status >/dev/null || { echo "NOT_RUNNING"; exit 0; }
echo "== folders"; api config/folders
for id in $(api config/folders | grep -o '"id": *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/'); do
  echo "== status $id"; api "db/status?folder=$id"
done
echo "== devices"; api config/devices
echo "== connections"; api system/connections
```

- `NO_CONFIG`: report "Syncthing is not set up on this machine."
- `NOT_RUNNING`: report "Syncthing is not running, so the vault is not being synced."

## Output

Return a short status summary:
- Running or not
- Per folder: sync state (`idle` = good, anything else = warn), files in sync X/Y
- Connected devices: names (match the IDs from `connections` to `devices`) and connection status
- If anything is wrong, explain what and suggest a fix
