# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
For detailed structure and conventions, see the
[Dotfiles Stow Setup](~/notes-vault/1777188230-dotfiles-stow-setup.md) note.

## Supported Systems

- macOS
- Ubuntu/Debian
- Fedora Atomic (Sway)
- Arch/Manjaro

## Installation

### Fresh Install (New System)

Requires `curl`. Install first if missing:
- Ubuntu/Debian: `sudo apt-get update && sudo apt install -y curl`
- Arch: `sudo pacman -S curl`

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/trunk/bootstrap.sh)
```

### Manual Install (Already Cloned)

```bash
git clone git@github.com:arjenbloemsma/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Notes Vault Only (Standalone)

For a temp/exploration machine — installs syncthing via the native package
manager, creates `~/notes-vault`, starts the service, pairs with the
always-on anchor node, and shares the `notes-vault` folder with it. No
full dotfiles install. Works on bare macOS (requires brew), Debian/Ubuntu,
Arch, Fedora.

The script needs the anchor's device ID — supplied via either a config
file or an env var. Device IDs leak IPs through the public discovery
server, so **do not commit them**; `scripts/notes-mesh.conf.local` is
gitignored.

**One-liner (no clone) — env var:**

```bash
NOTES_MESH_PEERS_ENV="DEVICE_ID|anchor-node" \
  bash <(curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/trunk/scripts/join-notes-mesh.sh)
```

Multiple peers (anchor plus optional direct P2P) — comma-separate them:
`"ID1|anchor,ID2|peer-2"`.

**Repo already cloned — config file:**

```bash
cp ~/dotfiles/scripts/notes-mesh.conf.template ~/dotfiles/scripts/notes-mesh.conf.local
# edit notes-mesh.conf.local with the anchor's device ID + name
~/dotfiles/scripts/join-notes-mesh.sh
```

**After running on the new box:** open the anchor's web UI from a
machine that already has SSH access to it (e.g. the primary workstation,
not the new box itself). Accept the two prompts — "New Device" for the
new hostname, then "New Folder" to share `notes-vault` back. Sync starts
automatically.

If the anchor's GUI binds to localhost (default), reach it via SSH tunnel
from that primary machine — pick a free local port to avoid clashing
with the local syncthing on `8384`:

```bash
ssh -L 8385:127.0.0.1:8384 anchor-host
# then http://127.0.0.1:8385 in the browser
```

### Fedora Atomic

Bootstrap layers minimal host packages (zsh, tmux, stow, syncthing, starship)
via `rpm-ostree`. Reboot after bootstrap for layered packages to take effect.

Dev tools live in a toolbox container:

```bash
toolbox create
toolbox enter
~/dotfiles/scripts/toolbox-setup.sh
```

### Post-install

- Edit `~/.config/git/config.local` with name and email
- Press `prefix + I` in tmux to install plugins

### Manage Packages

```bash
stow --restow <package-name>   # update
stow --delete <package-name>   # remove
./install.sh --dry-run          # preview changes
```

## Structure

Each top-level directory is a stow package. See `install.sh` for the
full list of packages, CLI tools, and GUI apps.

## Notes

- **Secrets**: Git user details go in `~/.config/git/config.local` (not tracked)
- **Tmux plugins**: Managed by TPM, not tracked in git
