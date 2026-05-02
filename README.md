# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
For detailed structure and conventions, see the
[Dotfiles Stow Setup](~/notes-vault/1777188230-dotfiles-stow-setup.md) note.

## Supported Systems

- macOS
- Ubuntu/Debian
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
manager, creates `~/notes-vault`, starts the syncthing service, and prints
the new node's device ID + Web UI URL for pairing from a peer. No full
dotfiles install. Works on bare macOS (requires brew), Debian/Ubuntu, Arch,
Fedora.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/trunk/scripts/join-notes-mesh.sh)
```

Or if the repo is already cloned:

```bash
~/dotfiles/scripts/join-notes-mesh.sh
```

### Post-install

- Edit `~/.config/git/config.local` with name and email
- Press `prefix + I` in tmux to install plugins

### Manage Packages

```bash
stow --restow <package-name>   # update
stow --delete <package-name>   # remove
./install.sh --dry-run          # preview changes
./install.sh --rollback <timestamp>  # rollback
```

## Structure

Each top-level directory is a stow package. See `install.sh` for the
full list of packages, CLI tools, and GUI apps.

## Notes

- **Secrets**: Git user details go in `~/.config/git/config.local` (not tracked)
- **Tmux plugins**: Managed by TPM, not tracked in git
