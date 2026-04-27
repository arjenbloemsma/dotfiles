#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR/dotfiles_$TIMESTAMP"
DRY_RUN=false
VERBOSE=false
ROLLBACK_TIMESTAMP=""

# Packages with config to stow (cross-platform)
STOW_PACKAGES=(
    "bat"
    "claude"
    "gh"
    "ghostty"
    "git"
    "glow"
    "lazygit"
    "nvim"
    "sesh"
    "starship"
    "tmux"
    "yazi"
    "zsh"
)

# macOS-only stow packages
STOW_PACKAGES_MACOS=(
    "skhd"
    "yabai"
)

# CLI tools to install via brew (cross-platform)
INSTALL=(
    "azure-cli"
    "azure-functions-core-tools@4"
    "bat"
    "bun"
    "docker"
    "fastfetch"
    "fd"
    "flyctl"
    "fnm"
    "fzf"
    "gh"
    "glow"
    "httpie"
    "jq"
    "lazydocker"
    "lazygit"
    "nvim"
    "pandoc"
    "powershell"
    "ripgrep"
    "semgrep"
    "sesh"
    "starship"
    "syncthing"
    "tmux"
    "tree"
    "yazi"
    "zoxide"
)

# Nerd Fonts — casks on macOS, manual install on Linux
FONTS=(
    "font-hack-nerd-font"
    "font-jetbrains-mono-nerd-font"
    "font-symbols-only-nerd-font"
)

# GUI apps — casks on macOS, package manager on Linux
APPS=(
    "balenaetcher"
    "claude-code"
    "firefox"
    "ghostty"
    "keycastr"
    "microsoft-azure-storage-explorer"
    "pgadmin4"
    "ungoogled-chromium"
    "vlc"
)

# Get app name for package on specific OS
get_app_name() {
    local package="$1"
    local os="$2"

    case "$package" in
        nvim) echo "neovim" ;;
        bun)
            case "$os" in
                macos) echo "bun" ;;
                *) ;; # installed via install script
            esac
            ;;
        yabai) echo "koekeishiya/formulae/yabai" ;;
        skhd) echo "koekeishiya/formulae/skhd" ;;
        azure-functions-core-tools@4) echo "azure/functions/azure-functions-core-tools@4" ;;
        gh)
            case "$os" in
                arch) echo "github-cli" ;;
                *) echo "gh" ;;
            esac
            ;;
        *) echo "$package" ;;
    esac
}

# Execute or dry-run a command
execute() {
    if [[ "$DRY_RUN" == true ]]; then
        [[ "$VERBOSE" == true ]] && echo -e "${BLUE}→${NC} Would run: $*"
    else
        "$@"
    fi
}

# Print message respecting dry-run and verbose
print_action() {
    local message="$1"
    local force="${2:-false}"

    # Always print if force=true, otherwise respect verbose
    if [[ "$force" == true ]] || [[ "$VERBOSE" == true ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${BLUE}→${NC} Would $message"
        else
            echo -e "${BLUE}→${NC} $message"
        fi
    fi
}

# Detect OS
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

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    command -v git >/dev/null 2>&1 || { echo -e "${RED}✗${NC} git not installed"; exit 1; }
    echo -e "${GREEN}✓${NC} git"

    command -v stow >/dev/null 2>&1 || { echo -e "${RED}✗${NC} stow not installed"; exit 1; }
    echo -e "${GREEN}✓${NC} stow"

    if command -v brew >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} homebrew"
    fi

    echo ""
}

# Install applications
install_applications() {
    local os=$(detect_os)
    local -a formulae=()
    local -a packages=("${INSTALL[@]}")

    # Add macOS-only packages
    if [[ "$os" == "macos" ]]; then
        packages+=("${STOW_PACKAGES_MACOS[@]}")
    fi

    echo "Installing applications for $os..."

    for package in "${packages[@]}"; do
        local app_name
        app_name=$(get_app_name "$package" "$os")
        [[ -n "$app_name" ]] && formulae+=("$app_name")
    done

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}→${NC} Would install formulae: ${formulae[*]}"
        echo -e "${BLUE}→${NC} Would install apps: ${APPS[*]}"
        echo ""
        return
    fi

    # Install formulae
    case "$os" in
        macos|ubuntu|debian)
            if command -v brew >/dev/null 2>&1; then
                brew install "${formulae[@]}"
            else
                echo -e "${YELLOW}⚠${NC} Homebrew not found, skipping"
                return
            fi
            ;;
        arch)
            yay -S --noconfirm "${formulae[@]}"
            ;;
        *)
            echo -e "${YELLOW}⚠${NC} Unknown OS, skipping"
            return
            ;;
    esac

    # Install tools that need custom install on Linux
    if [[ "$os" != "macos" ]]; then
        if ! command -v bun >/dev/null 2>&1; then
            echo "Installing bun..."
            curl -fsSL https://bun.sh/install | bash
        fi
    fi

    # Skip fonts and GUI apps in containers
    if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
        echo -e "${YELLOW}⚠${NC} Container detected, skipping fonts and GUI apps"
    else
        # Install fonts
        echo "Installing fonts..."
        if [[ "$os" == "macos" ]] && command -v brew >/dev/null 2>&1; then
            brew install --cask "${FONTS[@]}"
        elif [[ "$os" == "arch" ]]; then
            yay -S --noconfirm ttf-jetbrains-mono-nerd ttf-hack-nerd ttf-nerd-fonts-symbols-mono
        else
            mkdir -p "$HOME/.local/share/fonts"
            for font_url in \
                "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
                "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz" \
                "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz"; do
                curl -fsSL "$font_url" | tar xJ -C "$HOME/.local/share/fonts"
            done
            fc-cache -f
        fi

        # Install GUI apps
        echo "Installing apps..."
        if [[ "$os" == "macos" ]] && command -v brew >/dev/null 2>&1; then
            brew install --cask "${APPS[@]}"
        elif [[ "$os" == "arch" ]]; then
            yay -S --noconfirm "${APPS[@]}"
        fi
    fi

    echo -e "${GREEN}✓${NC} Applications installed"
    echo ""
}

# Backup a file
backup_file() {
    local file="$1"
    local relative_path="${file#$HOME/}"
    local backup_path="$BACKUP_DIR/files/$relative_path"

    if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
        execute mkdir -p "$(dirname "$backup_path")"
        execute cp -r "$file" "$backup_path"
        print_action "backup: $relative_path" false
        return 0
    fi
    return 1
}

# Check for conflicts in a package
check_package_conflicts() {
    local package="$1"
    local -a conflict_files=()

    cd "$DOTFILES_DIR/$package"

    # Let stow determine which files would be installed
    # Use stow's simulation to get the list
    local stow_files
    stow_files=$(stow --no --verbose=2 "$package" 2>&1 | grep "LINK:" | awk '{print $3}')

    while IFS= read -r target_path; do
        [[ -z "$target_path" ]] && continue

        local target_file="$HOME/$target_path"

        # Skip if target doesn't exist
        [[ ! -e "$target_file" ]] && continue

        # Check if it's a real file (conflict) or wrong symlink
        if [[ ! -L "$target_file" ]]; then
            # Real file - conflict
            conflict_files+=("$target_path")
        else
            # Symlink - check if points to our dotfiles
            local link_target=$(readlink "$target_file")
            local expected_prefix="$DOTFILES_DIR/$package"

            # Check if symlink points to our dotfiles
            if [[ ! "$link_target" =~ ^$expected_prefix ]]; then
                conflict_files+=("$target_path")
            fi
        fi
    done <<< "$stow_files"

    # Print summary if conflicts found
    if [[ ${#conflict_files[@]} -gt 0 ]]; then
        local count=${#conflict_files[@]}
        if [[ $count -le 3 ]]; then
            for file in "${conflict_files[@]}"; do
                echo -e "${YELLOW}  ⚠${NC} $file"
            done
        else
            echo -e "${YELLOW}  ⚠${NC} ${conflict_files[0]}"
            echo -e "${YELLOW}  ⚠${NC} ${conflict_files[1]}"
            echo -e "${YELLOW}  ⚠${NC} ... and $((count - 2)) more files"
        fi
        return 0
    fi

    return 1
}

# Setup git config.local
setup_git_config() {
    echo "Checking git config..."

    local config_local="$HOME/.config/git/config.local"
    local old_config="$HOME/.gitconfig.local"

    if [[ -f "$config_local" ]]; then
        echo -e "${GREEN}✓${NC} Git config.local exists"
    elif [[ -f "$old_config" ]]; then
        print_action "migrate $old_config to XDG location" true
        execute mkdir -p "$HOME/.config/git"
        execute mv "$old_config" "$config_local"
    else
        echo -e "${YELLOW}⚠${NC} $config_local not found"
        print_action "create from template" true
        execute mkdir -p "$HOME/.config/git"
        execute cp "$DOTFILES_DIR/git/.config/git/config.local.template" "$config_local"
        echo -e "${YELLOW}→${NC} Edit $config_local with your name and email"
    fi

    echo ""
}

# Check conflicts for all packages
check_all_conflicts() {
    echo "Checking for conflicts..."

    local has_conflicts=0
    local os=$(detect_os)
    local -a all_stow=("${STOW_PACKAGES[@]}")
    if [[ "$os" == "macos" ]]; then
        all_stow+=("${STOW_PACKAGES_MACOS[@]}")
    fi

    for package in "${all_stow[@]}"; do
        if [[ -d "$DOTFILES_DIR/$package" ]]; then
            if check_package_conflicts "$package"; then
                has_conflicts=1
            fi
        fi
    done

    if [[ $has_conflicts -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} No conflicts found"
    fi

    echo ""
}

# Install a single package
install_package() {
    local package="$1"

    if [[ ! -d "$DOTFILES_DIR/$package" ]]; then
        echo -e "${YELLOW}⚠${NC} $package directory not found, skipping"
        return
    fi

    if [[ "$DRY_RUN" == false ]]; then
        stow --delete "$package" 2>/dev/null || true
        stow --restow "$package"
        echo -e "${GREEN}✓${NC} $package"
    else
        echo -e "${BLUE}→${NC} Would install: $package"
    fi
}

# Install all packages
install_packages() {
    echo "Installing packages..."
    cd "$DOTFILES_DIR"
    local os=$(detect_os)

    for package in "${STOW_PACKAGES[@]}"; do
        install_package "$package"
    done

    if [[ "$os" == "macos" ]]; then
        for package in "${STOW_PACKAGES_MACOS[@]}"; do
            install_package "$package"
        done
    fi

    echo ""
}

# Install tmux plugin manager
install_tmux_plugins() {
    if [[ "$DRY_RUN" == true ]]; then
        return
    fi

    echo "Checking tmux plugins..."

    if [[ -d "$HOME/.config/tmux/plugins/tpm" ]]; then
        echo -e "${GREEN}✓${NC} TPM already installed"
    else
        echo -e "${YELLOW}→${NC} Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
        echo -e "${GREEN}✓${NC} TPM installed"
        echo -e "${YELLOW}→${NC} Run prefix + I in tmux to install plugins"
    fi

    echo ""
}

# Print completion message
print_completion() {
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}Dry run complete - no changes made${NC}"
        return
    fi

    echo -e "${GREEN}✓${NC} Dotfiles installation complete!"
    echo ""
    echo "Backup created at:"
    echo "  $BACKUP_DIR"
    echo ""
    echo "To rollback, run:"
    echo "  ./install.sh --rollback $TIMESTAMP"
    echo ""
    echo "Next steps:"
    echo "  1. Edit ~/.config/git/config.local with your git user details"
    echo "  2. Restart your shell or run: source ~/.config/zsh/.zshrc"
    echo "  3. Install tmux plugins: prefix + I (in tmux)"
    if ! command -v ghostty >/dev/null 2>&1; then
        echo "  4. Set terminal font to 'JetBrainsMono Nerd Font' for icon support"
    fi
}

# Rollback to a previous backup
rollback() {
    local rollback_dir="$BACKUP_BASE_DIR/dotfiles_$ROLLBACK_TIMESTAMP"

    if [[ ! -d "$rollback_dir" ]]; then
        echo -e "${RED}✗${NC} Backup directory not found: $rollback_dir"
        echo ""
        echo "Available backups:"
        ls -1 "$BACKUP_BASE_DIR" 2>/dev/null | grep "^dotfiles_" || echo "  None"
        exit 1
    fi

    echo "🔄 Rolling back from: $rollback_dir"
    echo ""

    if [[ -d "$rollback_dir/files" ]]; then
        cd "$rollback_dir/files"
        for file in $(find . -type f); do
            local target_file="$HOME/${file#./}"
            echo -e "${BLUE}→${NC} Restoring: $target_file"
            mkdir -p "$(dirname "$target_file")"
            cp "$file" "$target_file"
        done
    fi

    echo ""
    echo -e "${GREEN}✓${NC} Rollback complete"
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --rollback)
                ROLLBACK_TIMESTAMP="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Usage: $0 [--dry-run] [--verbose|-v] [--rollback TIMESTAMP]"
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"

    # Handle rollback mode
    if [[ -n "$ROLLBACK_TIMESTAMP" ]]; then
        rollback
    fi

    # Setup Homebrew environment for Linux (must be in main scope)
    local os=$(detect_os)
    if [[ "$os" == "ubuntu" ]] || [[ "$os" == "debian" ]]; then
        if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
    fi

    # Print header
    echo "🌸 Dotfiles Installation"
    [[ "$DRY_RUN" == true ]] && echo -e "${YELLOW}(DRY RUN MODE - no changes will be made)${NC}"
    echo ""

    # Setup backup directory
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$BACKUP_DIR/files"
    fi
    echo "Backup directory: $BACKUP_DIR"
    echo ""

    # Run installation steps
    check_prerequisites
    install_applications
    setup_git_config
    check_all_conflicts
    install_packages
    install_tmux_plugins
    print_completion
}

main "$@"
