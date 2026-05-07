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
    "fastfetch"
    "fd"
    "flyctl"
    "fnm"
    "fzf"
    "gh"
    "glow"
    "httpie"
    "jq"
    "lazygit"
    "nvim"
    "pandoc"
    "podman"
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

    # Fedora Atomic: host packages layered via bootstrap, dev tools go in toolbox
    if [[ "$os" == "fedora" ]] && [[ -f /run/ostree-booted ]]; then
        echo -e "${YELLOW}⚠${NC} Fedora Atomic: skipping app install (use toolbox-setup.sh for dev tools)"
        echo ""
        return
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
        macos|ubuntu|debian|fedora)
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

    # Install Nix (required by devbox) — cross-platform, non-interactive.
    # Uses Determinate Systems installer; --no-confirm skips the diagnostic-data prompt.
    # macOS still prompts for sudo to create the /nix volume.
    # /nix/receipt.json is the install marker the Determinate installer drops on success;
    # it's authoritative regardless of whether the current shell has the Nix PATH hooks loaded.
    if [[ ! -e /nix/receipt.json ]]; then
        echo "Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    fi

    # Install devbox (cross-platform official installer; uses the Nix installed above)
    if ! command -v devbox >/dev/null 2>&1; then
        echo "Installing devbox..."
        curl -fsSL https://get.jetify.com/devbox | bash
    fi

    # Install tools that need custom install on Linux
    if [[ "$os" != "macos" ]]; then
        if ! command -v bun >/dev/null 2>&1; then
            echo "Installing bun..."
            curl -fsSL https://bun.sh/install | bash
        fi
    fi

    # Install Node LTS via fnm (needed by Mason for LSPs)
    if command -v fnm >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
        echo "Installing Node LTS via fnm..."
        eval "$(fnm env --shell bash)" && fnm install --lts
        fnm default lts-latest # persist across shells, fnm env alone is session-only
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

        # Fedora Wayland: use foot instead of ghostty
        if [[ "$os" == "fedora" ]]; then
            if command -v foot >/dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} foot terminal present"
            else
                echo -e "${YELLOW}⚠${NC} foot terminal not found, install via: sudo dnf install foot"
            fi
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

# Classify each conflict for a package and auto-resolve safe ones.
# Categories:
# - Path resolves into the dotfiles repo (already stowed via direct symlink or tree-folded
#   parent dir) → no-op; stow will refresh the link as part of restow.
# - Real file with content identical to dotfiles version → backup + remove (safe replace).
# - Real file with differing content → unresolvable; human must reconcile.
# - Directory → unresolvable; recursive auto-merge is unsafe.
# - Symlink pointing outside the dotfiles repo → unresolvable.
# Returns 0 if package is clear, 1 if any unresolvable conflicts remain.
classify_and_resolve_conflicts() {
    local package="$1"
    local -a unresolvable=()

    # Walk the package via `git ls-files`: every tracked file maps to a target symlink at
    # $HOME/<rel_path>. Using git as the source of truth means the walk respects .gitignore
    # (so junk like .DS_Store, lockfiles, and backup dirs are excluded by the same rules
    # that keep them out of the repo).
    while IFS= read -r -d '' rel_path; do
        [[ -z "$rel_path" ]] && continue

        local target_file="$HOME/$rel_path"
        local source_file="$DOTFILES_DIR/$package/$rel_path"

        # Nothing there → no conflict
        [[ ! -e "$target_file" ]] && continue

        # CRITICAL SAFETY: resolve the target through every symlink in its path. If the
        # resolved location lives inside the dotfiles repo, the package is already stowed
        # — either by a direct symlink at this path, or via tree-folding (a parent dir is
        # a symlink and individual files are reached through it). In that case `rm` here
        # would delete the dotfile source itself. Skip and let stow refresh the link.
        local resolved_target
        resolved_target=$(readlink -f "$target_file" 2>/dev/null || echo "$target_file")
        if [[ "$resolved_target" == "$DOTFILES_DIR"/* ]]; then
            continue
        fi

        # Direct symlink pointing somewhere outside the dotfiles repo
        if [[ -L "$target_file" ]]; then
            unresolvable+=("symlink → $resolved_target: $rel_path")
            continue
        fi

        # Directory always needs human review
        if [[ -d "$target_file" ]]; then
            unresolvable+=("directory: $rel_path")
            continue
        fi

        # Real file: identical content → safe auto-resolve, otherwise unresolvable
        if cmp -s "$target_file" "$source_file" 2>/dev/null; then
            if [[ "$DRY_RUN" == false ]]; then
                backup_file "$target_file"
                rm -f "$target_file"
            fi
            print_action "resolved (identical): $rel_path" false
        else
            unresolvable+=("differs: $rel_path  (review: diff $target_file $source_file)")
        fi
    done < <(git -C "$DOTFILES_DIR/$package" ls-files -z)

    if [[ ${#unresolvable[@]} -gt 0 ]]; then
        echo -e "${RED}✗${NC} $package — unresolvable conflicts:" >&2
        for entry in "${unresolvable[@]}"; do
            echo -e "${RED}  ✗${NC} $entry" >&2
        done
        return 1
    fi

    return 0
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

# Resolve safe conflicts and abort on anything ambiguous, BEFORE any package gets stowed.
# Single complete picture for the user instead of a half-applied bootstrap.
check_all_conflicts() {
    echo "Checking for conflicts..."

    local has_unresolvable=0
    local os=$(detect_os)
    local -a all_stow=("${STOW_PACKAGES[@]}")
    if [[ "$os" == "macos" ]]; then
        all_stow+=("${STOW_PACKAGES_MACOS[@]}")
    fi

    for package in "${all_stow[@]}"; do
        if [[ -d "$DOTFILES_DIR/$package" ]]; then
            if ! classify_and_resolve_conflicts "$package"; then
                has_unresolvable=1
            fi
        fi
    done

    if [[ $has_unresolvable -eq 1 ]]; then
        echo "" >&2
        echo -e "${RED}✗${NC} Bootstrap aborted — resolve the conflicts above and re-run." >&2
        echo "    For files that differ: pick the canonical version (dotfiles or local)," >&2
        echo "    update the dotfiles repo or remove the local file accordingly." >&2
        exit 1
    fi

    echo -e "${GREEN}✓${NC} No conflicts (or all auto-resolved)"
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
