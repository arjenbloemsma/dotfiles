# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a stow package whose contents mirror the
target paths under `$HOME`. Running stow creates symlinks from `$HOME`
into the package; restow refreshes them.

## Supported Systems

- macOS — full support
- Ubuntu/Debian — full support (Homebrew on Linux for CLI tools)
- Fedora Atomic — host stays minimal (rpm-ostree layering for zsh,
  tmux, stow, syncthing); user-space host tools (starship, devpod)
  install to `~/.local/bin`; dev tools live in a toolbox container
- Arch — partial: bootstrap works, but some CLI/GUI names in
  `install.sh` are brew/cask names that don't map cleanly to AUR

Plain Fedora (non-Atomic) is not supported.

## Installation

### Fresh Install (New System)

Requires `curl`. Install first if missing:
- Ubuntu/Debian: `sudo apt-get update && sudo apt install -y curl`
- Arch: `sudo pacman -S curl`

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/trunk/bootstrap.sh)
```

### Manual Install (Already Cloned)

Assumes `git` and `stow` are already installed — `install.sh` aborts
if either is missing. For a clean machine, use the bootstrap one-liner
above instead.

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

On first run, bootstrap layers minimal host packages (zsh, tmux, stow,
syncthing) via `rpm-ostree` and **exits**. The layered packages are
only available after reboot, so the rest of the install (shell change,
stow) can't proceed yet. After reboot, `install.sh` adds user-space
host tools (starship, devpod) to `~/.local/bin`.

```bash
# First run: layers packages, then exits
bash <(curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/trunk/bootstrap.sh)

sudo systemctl reboot

# Second run: detects layered packages on PATH and continues through install.sh
bash <(curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/trunk/bootstrap.sh)
```

Dev tools live in a toolbox container, not on the host:

```bash
toolbox create
toolbox enter
~/dotfiles/scripts/toolbox-setup.sh
```

### Post-install

- Edit `~/.config/git/config.local` with name and email
- Press `prefix + I` in tmux to install plugins

### Manage Packages

Run from inside the dotfiles dir. Always pass `--target` to be explicit
about where symlinks land, regardless of where the repo is cloned:

```bash
stow --target="$HOME" --restow <package-name>   # update
stow --target="$HOME" --delete <package-name>   # remove
./install.sh --dry-run                          # preview changes
```

## Structure

See `install.sh` for the full list of stow packages, CLI tools, and
GUI apps. Shared package lists live in `scripts/lib/` and are sourced
by `install.sh` and `scripts/toolbox-setup.sh`.

## Notes

- **Secrets**: Git user details go in `~/.config/git/config.local` (not tracked)
- **Tmux plugins**: Managed by TPM, not tracked in git
