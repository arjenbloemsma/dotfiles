#!/usr/bin/env bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOTFILES_REPO="https://github.com/arjenbloemsma/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Host packages for the Linux desktops; names are the same on Fedora and Omarchy
HOST_PACKAGES=(tmux stow syncthing tailscale rbw neovim wireguard-tools)

# Detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID,,}"
    else
        echo "unknown"
    fi
}

# Install prerequisites based on OS
install_prerequisites() {
    local os=$(detect_os)

    echo "Detected OS: $os"
    echo ""
    echo "Installing prerequisites..."

    case "$os" in
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                echo -e "${YELLOW}→${NC} Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install bash git stow
            ;;
        ubuntu|debian)
            # Install build essentials and curl for Homebrew
            sudo apt update
            sudo apt install -y build-essential curl git

            if ! command -v brew >/dev/null 2>&1; then
                echo -e "${YELLOW}→${NC} Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                # Add Homebrew to PATH (idempotent — only append once)
                if ! grep -q "linuxbrew/.linuxbrew/bin/brew shellenv" "$HOME/.profile" 2>/dev/null; then
                    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
                fi
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            fi
            brew install stow
            ;;
        fedora)
            # Fedora Atomic: layer host-only packages. If any are missing, layer
            # them all (rpm-ostree is idempotent) and exit so the user reboots.
            # On the next run all packages pass the check and bootstrap continues.
            local missing=()
            local pkg
            for pkg in "${HOST_PACKAGES[@]}"; do
                rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
            done
            if (( ${#missing[@]} > 0 )); then
                rpm-ostree install --idempotent "${HOST_PACKAGES[@]}"
                echo ""
                echo -e "${YELLOW}→${NC} Layered packages installed (missing: ${missing[*]})."
                echo -e "${YELLOW}→${NC} Reboot now (sudo systemctl reboot), then re-run this bootstrap."
                exit 0
            fi
            ;;
        omarchy)
            # --needed skips what Omarchy already ships
            sudo pacman -S --needed --noconfirm "${HOST_PACKAGES[@]}"
            ;;
        *)
            echo -e "${RED}✗${NC} Unsupported OS: $os"
            echo "Supported: macOS, Fedora Atomic, Omarchy, Ubuntu"
            exit 1
            ;;
    esac

    echo -e "${GREEN}✓${NC} Prerequisites installed"
    echo ""
}



# Clone or update dotfiles repo
clone_dotfiles() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        echo "Updating dotfiles..."
        cd "$DOTFILES_DIR"
        git pull
        echo -e "${GREEN}✓${NC} Dotfiles updated"
        cd -
    else
        echo "Cloning dotfiles..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        echo -e "${GREEN}✓${NC} Dotfiles cloned"
    fi

    echo ""
}

# Apply host-level DNS convention (Linux only)
setup_system_dns() {
    local os
    os=$(detect_os)
    [[ "$os" == "macos" ]] && return 0

    local dns_script="$DOTFILES_DIR/scripts/setup-system-dns.sh"
    if [[ -x "$dns_script" ]]; then
        echo "Applying system-level DNS convention..."
        "$dns_script"
        echo ""
    fi
}

# Give the login greeter the dark wallpaper (Fedora Sway only)
setup_sddm_theme() {
    [[ "$(detect_os)" == "fedora" ]] || return 0
    command -v sway >/dev/null 2>&1 || return 0

    local sddm_script="$DOTFILES_DIR/scripts/setup-sddm-theme.sh"
    if [[ -x "$sddm_script" ]]; then
        echo "Setting the login greeter background..."
        "$sddm_script"
        echo ""
    fi
}

# Run install script
run_install() {
    cd "$DOTFILES_DIR"

    if [[ -x "./install.sh" ]]; then
        echo "Running install.sh..."
        echo ""
        ./install.sh "$@"
    else
        echo -e "${YELLOW}⚠${NC} install.sh not found or not executable"
        echo "Run manually: cd $DOTFILES_DIR && ./install.sh"
    fi
}

# Main
main() {
    echo "🚀 Dotfiles Bootstrap"
    echo ""

    install_prerequisites
    clone_dotfiles
    mkdir -p "$HOME/dev"
    setup_system_dns
    setup_sddm_theme
    run_install "$@"

    echo ""
    echo -e "${GREEN}✓${NC} Bootstrap complete!"
}

main "$@"
