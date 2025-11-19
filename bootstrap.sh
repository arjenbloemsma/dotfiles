#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOTFILES_REPO="git@github.com:arjenbloemsma/dotfiles.git"
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

                # Add Homebrew to PATH
                echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            fi
            brew install stow
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm git stow
            ;;
        *)
            echo -e "${RED}✗${NC} Unsupported OS: $os"
            echo "Supported: macOS, Ubuntu/Debian, Arch/Manjaro"
            exit 1
            ;;
    esac

    echo -e "${GREEN}✓${NC} Prerequisites installed"
    echo ""
}

# Check SSH key for GitHub
check_ssh_key() {
    echo "Checking SSH key..."

    if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
        echo -e "${YELLOW}⚠${NC} No SSH key found"
        echo ""
        echo "Generate SSH key:"
        echo "  ssh-keygen -t ed25519 -C \"your.email@example.com\""
        echo ""
        echo "Add to GitHub:"
        echo "  cat ~/.ssh/id_ed25519.pub"
        echo "  https://github.com/settings/keys"
        echo ""
        read -p "Press Enter after adding SSH key to GitHub..."
    else
        echo -e "${GREEN}✓${NC} SSH key exists"
    fi

    echo ""
}

# Clone dotfiles repo
clone_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        echo -e "${GREEN}✓${NC} Dotfiles already cloned at $DOTFILES_DIR"
        return
    fi

    echo "Cloning dotfiles..."

    if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null; then
        echo -e "${RED}✗${NC} Failed to clone with SSH"
        echo ""
        echo "Trying HTTPS fallback..."
        HTTPS_REPO="https://github.com/arjenbloemsma/dotfiles.git"
        git clone "$HTTPS_REPO" "$DOTFILES_DIR"
        echo -e "${YELLOW}⚠${NC} Cloned via HTTPS - configure SSH for push access later"
    fi

    echo -e "${GREEN}✓${NC} Dotfiles cloned"
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
    check_ssh_key
    clone_dotfiles
    run_install "$@"

    echo ""
    echo -e "${GREEN}✓${NC} Bootstrap complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Configure git: edit ~/.config/git/config.local"
    echo "  2. Restart shell: exec \$SHELL"
}

main "$@"
