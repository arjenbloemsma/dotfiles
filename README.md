# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

- macOS
- [Homebrew](https://brew.sh/)
- GNU Stow: `brew install stow`
- Git

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

### Fresh Install

1. Clone repository:
   ```bash
   git clone git@github.com:arjenbloemsma/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Create local git config with your details:
   ```bash
   cp git/.gitconfig.local.template ~/.gitconfig.local
   # Edit ~/.gitconfig.local with your name and email
   ```

3. Install packages (use `./install.sh` when available, or manually):
   ```bash
   stow git zsh ghostty starship tmux yabai skhd yazi gh
   ```

4. Install tmux plugins:
   ```bash
   # Press prefix + I (capital i) in tmux to install plugins
   # Or run: ~/.config/tmux/plugins/tpm/bin/install_plugins
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
