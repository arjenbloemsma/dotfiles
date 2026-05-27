#!/usr/bin/env bash
# Sets up a Fedora toolbox container with dev tools.
# Run inside: toolbox enter && ~/dotfiles/scripts/toolbox-setup.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

source "$(dirname "${BASH_SOURCE[0]}")/lib/stow-packages.sh"

# Verify we're inside a toolbox
if [[ ! -f /run/.containerenv ]]; then
    echo -e "${RED}✗${NC} Not inside a toolbox/container. Run: toolbox enter"
    exit 1
fi

echo "Setting up toolbox dev environment..."

# Core dev tools via dnf
sudo dnf install -y \
    bat \
    fastfetch \
    fd-find \
    fzf \
    httpie \
    jq \
    neovim \
    pandoc \
    ripgrep \
    tmux \
    tree \
    zoxide \
    stow

# lazygit and yazi aren't in default Fedora repos — pulled from COPRs
sudo dnf copr enable -y atim/lazygit
sudo dnf copr enable -y lihaohong/yazi
sudo dnf install -y lazygit yazi

# Install bun
if ! command -v bun >/dev/null 2>&1; then
    echo "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
fi

# Install fnm + Node LTS
if ! command -v fnm >/dev/null 2>&1; then
    echo "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash
fi
eval "$(fnm env --shell bash)" && fnm install --lts
fnm default lts-latest # persist across shells

# Install starship
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install sesh
if ! command -v sesh >/dev/null 2>&1; then
    echo "Installing sesh..."
    mkdir -p "$HOME/.local/bin"
    curl -fL --progress-bar https://github.com/joshmedeski/sesh/releases/latest/download/sesh_Linux_x86_64.tar.gz \
        | tar -xz -C "$HOME/.local/bin" sesh
fi

# Install gh (GitHub CLI)
if ! command -v gh >/dev/null 2>&1; then
    echo "Installing gh..."
    sudo dnf install -y 'dnf-command(config-manager)'
    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo dnf install -y gh
fi

# Stow dotfiles (~/dotfiles is shared from host via $HOME)
if [[ -d "$HOME/dotfiles" ]]; then
    cd "$HOME/dotfiles"
    stow "${STOW_PACKAGES[@]}" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Dotfiles stowed"
fi

echo ""
echo -e "${GREEN}✓${NC} Toolbox setup complete!"
echo "Open nvim to trigger Mason LSP installs."
