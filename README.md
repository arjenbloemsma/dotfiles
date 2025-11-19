# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Supported Systems

- macOS
- Ubuntu/Debian
- Arch/Manjaro

## Packages

- **git** - Git configuration (user details in `~/.gitconfig.local`)
- **zsh** - Shell configuration with aliases and tools
- **ghostty** - Terminal emulator
- **starship** - Cross-shell prompt
- **tmux** - Terminal multiplexer with plugins
- **yabai** - Tiling window manager
- **skhd** - Hotkey daemon
- **yazi** - Terminal file manager
- **gh** - GitHub CLI

## Installation

### Fresh Install (New System)

Run bootstrap script (installs prerequisites, clones repo, runs install):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/main/bootstrap.sh)
```

Or manually:

```bash
# Download bootstrap script
curl -fsSL https://raw.githubusercontent.com/arjenbloemsma/dotfiles/main/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

### Manual Install (Already Cloned)

1. Clone repository:
   ```bash
   git clone git@github.com:arjenbloemsma/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Run install script:
   ```bash
   ./install.sh
   ```

3. Configure git user details:
   ```bash
   # Edit ~/.config/git/config.local with your name and email
   ```

4. Install tmux plugins:
   ```bash
   # Press prefix + I (capital i) in tmux to install plugins
   ```

### Update Existing

```bash
cd ~/dotfiles
git pull
stow --restow <package-name>
```

### Remove Package

```bash
cd ~/dotfiles
stow --delete <package-name>
```

## Structure

```
dotfiles/
├── git/
│   ├── .gitconfig              # Public config
│   └── .gitconfig.local.template  # Template for secrets
├── zsh/
│   └── .config/zsh/.zshrc
├── ghostty/
│   └── .config/ghostty/config
└── ...
```

## Notes

- **Secrets**: Never commit secrets. Git user details go in `~/.gitconfig.local` (not tracked)
- **Tmux plugins**: Managed by TPM, not tracked in git

## Tools Used

- **Zoxide** - Smarter cd command
- **fzf** - Fuzzy finder
- **fnm** - Fast Node version manager
- **Fastfetch** - System info display
