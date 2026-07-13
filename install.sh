#!/usr/bin/env bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
VERBOSE=false

source "$DOTFILES_DIR/scripts/lib/stow-packages.sh"
source "$DOTFILES_DIR/scripts/lib/download.sh"

# CLI tools to install via brew (cross-platform)
INSTALL=(
    "azure-cli"
    "azure-functions-core-tools@4"
    "bat"
    "bitwarden-cli"
    "bun"
    "fastfetch"
    "fd"
    "flyctl"
    "fnm"
    "fzf"
    "httpie"
    "jq"
    "nvim"
    "pandoc"
    "podman"
    # pdftotext/pdftoppm — lets tooling read PDFs
    "poppler"
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

# GUI apps — Homebrew casks (macOS only). Linux uses APPS_FLATPAK below.
APPS=(
    "balenaetcher"
    "claude-code"
    "firefox"
    "ghostty"
    "microsoft-azure-storage-explorer"
    "pgadmin4"
    "tailscale"
    "vlc"
)

# GUI apps for Linux — Flathub IDs. Subset of APPS that's actually on flathub.
# pgadmin4, microsoft-azure-storage-explorer, claude-code: parked as devtools
# (revisit later). balenaetcher: macOS-only workflows.
APPS_FLATPAK=(
    "org.mozilla.firefox"
    "org.videolan.VLC"
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
        bitwarden-cli)
            case "$os" in
                macos) echo "bitwarden-cli" ;;
                *) ;; # Linux: installed as a binary to ~/.local/bin
            esac
            ;;
        yabai) echo "koekeishiya/formulae/yabai" ;;
        skhd) echo "koekeishiya/formulae/skhd" ;;
        azure-functions-core-tools@4) echo "azure/functions/azure-functions-core-tools@4" ;;
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

# Append OS-specific stow packages to the given array (passed by name).
append_os_packages() {
    local -n target=$1
    local os
    os=$(detect_os)
    if [[ "$os" == "macos" ]]; then
        target+=("${STOW_PACKAGES_MACOS[@]}")
    else
        target+=("${STOW_PACKAGES_LINUX[@]}")
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

# Provision a Fedora Atomic host for the devpod-based workflow.
# Host stays minimal: host packages (tmux, stow, syncthing) come from
# rpm-ostree layering in bootstrap.sh; user-space host tools that
# can't or shouldn't be layered install to ~/.local/bin and
# ~/.docker/cli-plugins/. Per-project dev environments live in each
# repo's .devcontainer/ and run via `devpod up <repo>`.
setup_fedora_atomic_host() {
    mkdir -p "$HOME/.local/bin"
    if ! command -v starship >/dev/null 2>&1; then
        echo "Installing starship to ~/.local/bin..."
        # Installer prints ~50 lines of per-shell setup notes — redirect to
        # /dev/null. Verify the binary lands and runs, since "installer exited
        # 0" alone is not proof of a working binary.
        if curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null \
            && [[ -x "$HOME/.local/bin/starship" ]] \
            && "$HOME/.local/bin/starship" --version >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} starship installed"
        else
            echo -e "${RED}✗${NC} starship install failed" >&2
            return 1
        fi
    fi
    if ! command -v devpod >/dev/null 2>&1; then
        echo "Installing devpod to ~/.local/bin..."
        download_binary \
            "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64" \
            "$HOME/.local/bin/devpod"
    fi
    if ! command -v bw >/dev/null 2>&1; then
        echo "Installing Bitwarden CLI to ~/.local/bin..."
        download_zipped_binary \
            "https://vault.bitwarden.com/download/?app=cli&platform=linux" \
            bw "$HOME/.local/bin"
    fi
    # docker-compose v2. `podman compose` looks in ~/.docker/cli-plugins/
    # and delegates to whatever it finds there. Needed because devpod
    # calls `compose ls`, which podman-compose v1 doesn't support.
    if [[ ! -x "$HOME/.docker/cli-plugins/docker-compose" ]]; then
        echo "Installing docker-compose v2 to ~/.docker/cli-plugins/..."
        download_binary \
            "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
            "$HOME/.docker/cli-plugins/docker-compose"
    fi
    # podman's user socket exposes a Docker-compatible API at
    # /run/user/$UID/podman/podman.sock. docker-compose v2 (and devpod
    # through it) talks to this as if it were a Docker daemon.
    systemctl --user enable --now podman.socket >/dev/null
    sudo systemctl enable --now tailscaled >/dev/null
    # devpod provider: tell its 'docker' provider to use podman + the
    # podman user socket. devpod runs subprocesses with a clean env, so
    # the shell-level DOCKER_HOST does not carry through; the value has
    # to live in devpod's own provider config.
    devpod provider add docker 2>/dev/null || true
    devpod provider set-options docker \
        -o DOCKER_PATH=podman \
        -o DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock" >/dev/null
    # Dotfiles hook: devpod clones this repo inside every container and runs
    # the configured script, which stows the devcontainer-only packages.
    devpod context set-options \
        -o DOTFILES_URL=https://github.com/arjenbloemsma/dotfiles \
        -o DOTFILES_SCRIPT=scripts/devcontainer-install.sh >/dev/null
    echo -e "${GREEN}✓${NC} Fedora Atomic: host provisioned (per-project dev envs via devpod)"
    echo ""
}

# Provision a macOS host for the devpod-based workflow.
# Installs the devpod CLI via brew, points its docker provider at podman
# (Mac uses a podman machine, not a system daemon), and sets the dotfiles
# context options so every devcontainer gets the personal config.
setup_macos_devpod_host() {
    if ! podman machine list --format '{{.Name}}' 2>/dev/null | grep -q .; then
        echo "Initializing podman machine..."
        # Sized for parallel TS/Svelte builds and an LSP that sits at ~1-2 GiB.
        podman machine init --cpus 4 --memory 4096 --disk-size 100
    fi
    if ! podman machine list --format '{{.Running}}' 2>/dev/null | grep -q true; then
        echo "Starting podman machine..."
        podman machine start
    fi
    if ! command -v devpod >/dev/null 2>&1; then
        echo "Installing devpod via brew..."
        brew install loft-sh/tap/devpod
    fi
    devpod provider add docker 2>/dev/null || true
    devpod provider set-options docker \
        -o DOCKER_PATH=podman >/dev/null
    devpod context set-options \
        -o DOTFILES_URL=https://github.com/arjenbloemsma/dotfiles \
        -o DOTFILES_SCRIPT=scripts/devcontainer-install.sh >/dev/null
    echo -e "${GREEN}✓${NC} macOS: devpod provisioned"
    echo ""
}

# Install applications
install_applications() {
    local os=$(detect_os)
    local -a formulae=()
    local -a packages=("${INSTALL[@]}")

    # Add OS-specific packages
    append_os_packages packages

    if [[ "$os" == "fedora" ]] && [[ -f /run/ostree-booted ]]; then
        setup_fedora_atomic_host
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
        if ! command -v bw >/dev/null 2>&1; then
            echo "Installing Bitwarden CLI..."
            download_zipped_binary \
                "https://vault.bitwarden.com/download/?app=cli&platform=linux" \
                bw "$HOME/.local/bin"
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
        # Install Nerd Fonts (macOS only — the Linux shell + tmux setup uses a
        # bare prompt and default status bar that don't need icon glyphs).
        if [[ "$os" == "macos" ]] && command -v brew >/dev/null 2>&1; then
            echo "Installing fonts..."
            brew install --cask "${FONTS[@]}"
        fi

        # Install GUI apps
        echo "Installing apps..."
        if [[ "$os" == "macos" ]] && command -v brew >/dev/null 2>&1; then
            brew install --cask "${APPS[@]}"
        elif command -v flatpak >/dev/null 2>&1; then
            flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
            flatpak install --user -y flathub "${APPS_FLATPAK[@]}"
        else
            echo -e "${YELLOW}⚠${NC} flatpak not found, skipping GUI apps"
        fi

        # Fedora Wayland: use foot instead of ghostty
        if [[ "$os" == "fedora" ]]; then
            if command -v foot >/dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} foot terminal present"
            else
                echo -e "${YELLOW}⚠${NC} foot terminal not found, install via: sudo dnf install foot"
            fi
        fi

        if [[ "$os" == "macos" ]]; then
            setup_macos_devpod_host
        fi
    fi

    echo -e "${GREEN}✓${NC} Applications installed"
    echo ""
}

# Classify each conflict for a package and auto-resolve safe ones.
# Categories:
# - Path resolves into the dotfiles repo (already stowed via direct symlink or tree-folded
#   parent dir) → no-op; stow will refresh the link as part of restow.
# - Real file with content identical to dotfiles version → remove (safe replace).
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

        # CRITICAL SAFETY: bash's -ef returns true when both paths point to
        # the same file on disk, no matter what symlinks are in between.
        # Catches every "already stowed" shape — including when the file is
        # reached through a symlinked parent directory. Without this, the
        # next check would see target and source as identical, run `rm`, and
        # delete the dotfiles source through the symlink chain.
        if [[ "$target_file" -ef "$source_file" ]]; then
            continue
        fi

        # Symlink pointing somewhere other than the source (or broken)
        if [[ -L "$target_file" ]]; then
            local link_dest
            link_dest=$(readlink -f "$target_file" 2>/dev/null || readlink "$target_file")
            unresolvable+=("symlink → $link_dest: $rel_path")
            continue
        fi

        # Directory always needs human review
        if [[ -d "$target_file" ]]; then
            unresolvable+=("directory: $rel_path")
            continue
        fi

        # Real file: identical content → safe auto-resolve. Differing content → show
        # the diff and ask for approval; accepting replaces the local file, declining
        # marks the package unresolvable and aborts.
        if cmp -s "$target_file" "$source_file" 2>/dev/null; then
            if [[ "$DRY_RUN" == false ]]; then
                rm -f "$target_file"
            fi
            print_action "resolved (identical): $rel_path" false
        elif [[ "$DRY_RUN" == true ]]; then
            unresolvable+=("differs (dry-run, skipped prompt): $rel_path")
        else
            echo -e "${YELLOW}⚠${NC} $rel_path differs from dotfiles version" >&2
            echo "─── diff: $target_file vs $source_file ───" >&2
            diff "$target_file" "$source_file" || true
            echo "─── end diff ───" >&2
            local ans
            read -r -p "Replace? [y/N] " ans </dev/tty
            if [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]; then
                rm -f "$target_file"
                print_action "replaced after approval: $rel_path" false
            else
                unresolvable+=("differs (declined): $rel_path")
            fi
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
    local -a all_stow=("${STOW_PACKAGES[@]}")
    append_os_packages all_stow

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
        stow --target="$HOME" --restow "$package"
        echo -e "${GREEN}✓${NC} $package"
    else
        echo -e "${BLUE}→${NC} Would install: $package"
    fi
}

# Install all packages
install_packages() {
    echo "Installing packages..."
    cd "$DOTFILES_DIR"

    local -a all_packages=("${STOW_PACKAGES[@]}")
    append_os_packages all_packages

    for package in "${all_packages[@]}"; do
        install_package "$package"
    done

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
    local rc_file
    if [[ "$(detect_os)" == "macos" ]]; then
        rc_file="~/.config/zsh/.zshrc"
    else
        rc_file="~/.bashrc"
    fi

    echo "Next steps:"
    echo "  1. Edit ~/.config/git/config.local with your git user details"
    echo "  2. Restart your shell or run: source $rc_file"
    echo "  3. Install tmux plugins: prefix + I (in tmux)"
    if command -v tailscale >/dev/null 2>&1 && ! tailscale status >/dev/null 2>&1; then
        echo "  4. Sign into tailnet: sudo tailscale up"
    fi
    if [[ "$(detect_os)" == "macos" ]] && ! command -v ghostty >/dev/null 2>&1; then
        echo "  5. Set terminal font to 'JetBrainsMono Nerd Font' for icon support"
    fi
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
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Usage: $0 [--dry-run] [--verbose|-v]"
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"

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
