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
            brew install git stow
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
            # Fedora Atomic: layer host-only packages, dev tools go in toolbox.
            # Layered packages aren't on PATH until reboot, so the rest of bootstrap
            # (chsh to zsh, install.sh requiring stow) can't proceed yet. Exit cleanly
            # and let the user re-run after reboot — second run is idempotent.
            if ! command -v zsh >/dev/null 2>&1 || ! command -v stow >/dev/null 2>&1; then
                rpm-ostree install --idempotent zsh tmux stow syncthing starship
                echo ""
                echo -e "${YELLOW}→${NC} Layered packages installed."
                echo -e "${YELLOW}→${NC} Reboot now (sudo systemctl reboot), then re-run this bootstrap."
                exit 0
            fi
            ;;
        arch)
            # Install base packages with pacman
            sudo pacman -S --noconfirm git stow base-devel

            # Install yay if not present
            if ! command -v yay >/dev/null 2>&1; then
                echo -e "${YELLOW}→${NC} Installing yay..."
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                cd /tmp/yay
                makepkg -si --noconfirm
                cd -
                rm -rf /tmp/yay
                echo -e "${GREEN}✓${NC} yay installed"
            fi
            ;;
        *)
            echo -e "${RED}✗${NC} Unsupported OS: $os"
            echo "Supported: macOS, Ubuntu, Fedora Atomic, Arch"
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

# Setup zsh as default shell
setup_zsh() {
    local os=$(detect_os)

    echo "Setting up zsh..."

    # Install zsh if not present
    if ! command -v zsh >/dev/null 2>&1; then
        case "$os" in
            macos)
                brew install zsh
                ;;
            ubuntu|debian)
                sudo apt install -y zsh
                ;;
            arch)
                yay -S --noconfirm zsh
                ;;
        esac
        echo -e "${GREEN}✓${NC} zsh installed"
    else
        echo -e "${GREEN}✓${NC} zsh already installed"
    fi

    # Set zsh as default shell if not already
    if [[ "${SHELL:-}" != *"zsh"* ]]; then
        local zsh_path=$(which zsh)
        echo -e "${YELLOW}→${NC} Changing default shell to zsh..."
        if [[ "$os" == "fedora" ]] && [[ -f /run/ostree-booted ]]; then
            sudo lchsh "$(whoami)" # Atomic: /etc/passwd is immutable, chsh won't work
        else
            sudo chsh -s "$zsh_path" "$(whoami)" # sudo to avoid PAM password prompt in containers
        fi
        echo -e "${GREEN}✓${NC} Default shell changed to zsh"
        echo -e "${YELLOW}→${NC} Log out and back in for shell change to take effect"
    else
        echo -e "${GREEN}✓${NC} zsh already default shell"
    fi

    # Setup XDG_CONFIG_HOME and ZDOTDIR in .zshenv
    if [[ ! -f "$HOME/.zshenv" ]]; then
        echo -e "${YELLOW}→${NC} Creating ~/.zshenv..."
        cat > "$HOME/.zshenv" << 'EOF'
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF
        echo -e "${GREEN}✓${NC} XDG_CONFIG_HOME and ZDOTDIR configured"
    else
        # Update existing .zshenv if needed
        if ! grep -q "XDG_CONFIG_HOME" "$HOME/.zshenv" 2>/dev/null; then
            echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> "$HOME/.zshenv"
        fi
        if ! grep -q "ZDOTDIR" "$HOME/.zshenv" 2>/dev/null; then
            echo 'export ZDOTDIR="$XDG_CONFIG_HOME/zsh"' >> "$HOME/.zshenv"
            echo -e "${GREEN}✓${NC} ZDOTDIR configured"
        else
            echo -e "${GREEN}✓${NC} XDG_CONFIG_HOME and ZDOTDIR already configured"
        fi
    fi

    echo ""
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
    setup_zsh
    clone_dotfiles
    mkdir -p "$HOME/dev"
    run_install "$@"

    echo ""
    echo -e "${GREEN}✓${NC} Bootstrap complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Configure git: edit ~/.config/git/config.local"
    echo "  2. Log out and back in for shell changes to take effect"
}

main "$@"
