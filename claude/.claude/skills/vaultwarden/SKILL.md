---
name: vaultwarden
description: Read secrets from, or add secrets to, the self-hosted Vaultwarden (Bitwarden-compatible) vault, without exposing values on the command line. Use when a script or task needs a credential from the vault, when moving credentials into it, or when clearing plaintext secrets out of files.
user-invocable: true
disable-model-invocation: false
allowed-tools: [Bash, Read]
---

# Vaultwarden

Reads and writes items in the self-hosted Vaultwarden (URL in
`rbw config show`, Tailscale-only). `rbw` for reads, `bw` for writes. See
[vaultwarden-workload](~/notes-vault/1779713664-vaultwarden-workload.md).

## Rules

- Never put a secret value in argv (visible via `ps`). The helper reads it from
  the `SECRET` env var. Do NOT `echo` secrets or pass them as script arguments.
- Do all secret handling in a single Bash call; keep values in shell vars.
- Adding or updating a login: ask which YubiKeys are registered on that
  account and set the matching `yubikey 1` / `yubikey 2` fields
  (`--yubikey` on add-item.sh, or see YubiKey fields).
- Never print a secret back. Verify by name/id only (see below).
- Master password / TOTP: the **user** unlocks. Never handle the master password.

## Quick start

1. Unlock. `bw unlock` needs interactive input, so exporting `BW_SESSION` in the
   agent's shell does not work. The user unlocks in a **separate terminal** and
   writes the token to a file (Tailscale must be up; `bw login` first time only):
   ```
   bw unlock --raw > <scratchpad>/bw-session
   ```
   Read it in every Bash call that needs it, and `rm` the file when done:
   ```
   export BW_SESSION="$(cat <scratchpad>/bw-session)"
   bw status --session "$BW_SESSION"     # expect "unlocked"
   ```

2. Search before writing. Duplicates have to be reconciled by hand:
   ```
   bw list items --search "<service>" --session "$BW_SESSION" \
     | jq -r '.[] | "\(.name)  \(.id)  \(.login.username // "-")"'
   ```

3. Add a secret (Secure Note, the default, for tokens/keys/API secrets):
   ```
   SECRET='ghp_xxx' ~/.claude/skills/vaultwarden/scripts/add-item.sh --name "GitHub PAT (Client)" \
       --folder "Client" --note "CI connection"
   ```

4. Add a login (username + password, e.g. a service account):
   ```
   SECRET='the-password' ~/.claude/skills/vaultwarden/scripts/add-item.sh --type login \
       --name "Service account" --username "user@example.com" \
       --folder "Client"
   ```

## YubiKey fields

Login items carry one Boolean custom field (type 2) per registered key:
`yubikey 1` (primary) and `yubikey 2` (backup), set to true once that key
is registered on the account.

Set one (item JSON goes through a pipe, never argv; `F` is the field name):
```
F="yubikey 1"
bw get item <id> --session "$BW_SESSION" \
  | jq --arg f "$F" '.fields = ((.fields // []) | map(select(.name != $f))
        + [{"name":$f,"value":"true","type":2}])' \
  | bw encode | bw edit item <id> --session "$BW_SESSION" >/dev/null
```

List items with registered keys, names + ids only:
```
bw sync --session "$BW_SESSION"
bw list items --session "$BW_SESSION" \
  | jq -r '.[] | [.fields[]? | select(.type==2 and (.name|startswith("yubikey ")) and .value=="true") | .name] as $k
           | select($k | length > 0) | "\(.name)  \(.id)  \($k | join(", "))"'
```

## Troubleshooting

`rbw sync` fails with `missing field access_token`, or a new item is missing
while old ones read fine: the 30 day device trust lapsed. Reads keep working
from a stale cache, so nothing flags it. Offer this cause first.

Fix (user runs it, TOTP required): `rbw purge`, then `rbw register` and
`rbw login`. Register without the purge does nothing. See
[rbw stops syncing every 30 days](~/notes-vault/1788272240-rbw-stops-syncing-every-30-days.md).

## Batch migration

When clearing many secrets out of a source file:

1. Read the source and list every secret with a proposed name/type/folder.
   Confirm the list with the user before writing anything.
2. In ONE Bash call, set each `SECRET` inline and invoke the helper per item.
   Keep values only in that call; never write them to an intermediate file.
3. Verify all landed (names + ids only, no secret values):
   ```
   bw sync --session "$BW_SESSION"
   bw list items --search "" --session "$BW_SESSION" | jq -r '.[] | "\(.name)  \(.id)"'
   ```
4. Only after every item is confirmed present, delete the secrets from the
   source file. Leave a note tracking any that still need **rotation** at
   source (a secret that sat in a synced/plaintext file may be compromised).

## Helpers

`~/.claude/skills/vaultwarden/scripts/get-item.sh ITEM [--key KEY]` reads one item, or one value from a
`key=value` body. Needs the rbw agent unlocked, no session token. Appends the
trailing newline rbw omits, without which a `while read` loop drops the last line.

`~/.claude/skills/vaultwarden/scripts/add-item.sh` creates one item. `--type note` (default) puts the
value in the Secure Note body; `--type login` puts it in the password field.
`--folder` is resolved by name and created if missing. `--yubikey 1` and
`--yubikey 2` set the YubiKey fields on a login. Requires `BW_SESSION`.
