#!/usr/bin/env bash
#
# Join this machine to the notes-vault syncthing mesh.
#
# - Installs syncthing if missing (native package manager only, no brew on Linux)
# - Creates ~/notes-vault
# - Starts syncthing as a user service
# - Prints device ID + Web UI URL so you can pair it from a peer
#
# Safe to re-run. Works on macOS (requires brew), Debian/Ubuntu, Arch, Fedora.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VAULT_DIR="$HOME/notes-vault"

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

# Fail fast if the package manager we expect isn't actually usable
# Verify a package manager binary is present and runnable. Exits on failure.
check_pkg_manager() {
    local cmd="$1"
    local hint="${2:-}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} $cmd not found${hint:+ — $hint}"
        exit 1
    fi
    if ! "$cmd" --version >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} $cmd is broken (--version failed)"
        exit 1
    fi
}

require_pkg_manager() {
    local os="$1"
    case "$os" in
        macos)         check_pkg_manager brew "install brew first or run bootstrap.sh" ;;
        ubuntu|debian) check_pkg_manager apt-get ;;
        arch)          check_pkg_manager pacman ;;
        fedora)        check_pkg_manager dnf ;;
        *)
            echo -e "${RED}✗${NC} Unsupported OS: $os (supported: macos, ubuntu, debian, arch, fedora)"
            exit 1
            ;;
    esac
    echo -e "${GREEN}✓${NC} package manager ready ($os)"
}

install_syncthing() {
    local os="$1"

    if command -v syncthing >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} syncthing already installed ($(syncthing --version | head -1))"
        return
    fi

    echo -e "${YELLOW}→${NC} Installing syncthing..."
    case "$os" in
        macos)        brew install syncthing ;;
        ubuntu|debian) sudo apt-get update && sudo apt-get install -y syncthing ;;
        arch)         sudo pacman -S --noconfirm syncthing ;;
        fedora)       sudo dnf install -y syncthing ;;
    esac
    echo -e "${GREEN}✓${NC} syncthing installed"
}

create_vault() {
    if [[ -d "$VAULT_DIR" ]]; then
        echo -e "${GREEN}✓${NC} vault directory exists: $VAULT_DIR"
    else
        mkdir -p "$VAULT_DIR"
        echo -e "${GREEN}✓${NC} created vault directory: $VAULT_DIR"
    fi
}

start_syncthing() {
    local os="$1"

    case "$os" in
        macos)
            if brew services list | grep -q '^syncthing.*started'; then
                echo -e "${GREEN}✓${NC} syncthing already running (brew services)"
            else
                brew services start syncthing
                echo -e "${GREEN}✓${NC} syncthing started via brew services"
            fi
            ;;
        ubuntu|debian|arch|fedora)
            if ! systemctl --user >/dev/null 2>&1; then
                echo -e "${YELLOW}⚠${NC} systemd user session unavailable — falling back to background process"
                if pgrep -u "$USER" -x syncthing >/dev/null; then
                    echo -e "${GREEN}✓${NC} syncthing already running"
                else
                    nohup syncthing --no-browser >/dev/null 2>&1 &
                    echo -e "${GREEN}✓${NC} syncthing started in background (no systemd)"
                fi
                return
            fi

            sudo loginctl enable-linger "$USER" 2>/dev/null || true
            systemctl --user enable --now syncthing.service
            echo -e "${GREEN}✓${NC} syncthing enabled and started (systemctl --user)"
            ;;
    esac
}

# Wait for syncthing to write its config (first run) or already have one
wait_for_config() {
    local config_path="$1"
    local tries=20
    while (( tries-- > 0 )); do
        [[ -f "$config_path" ]] && return 0
        sleep 1
    done
    return 1
}

config_path_for() {
    local os="$1"
    case "$os" in
        macos) echo "$HOME/Library/Application Support/Syncthing/config.xml" ;;
        *)     echo "${XDG_STATE_HOME:-$HOME/.local/state}/syncthing/config.xml" ;;
    esac
}

print_join_info() {
    local os="$1"
    local config_path
    config_path=$(config_path_for "$os")

    echo ""
    echo "Waiting for syncthing config..."
    if ! wait_for_config "$config_path"; then
        echo -e "${YELLOW}⚠${NC} config not found at $config_path — syncthing may still be starting"
        echo "   Run: syncthing --device-id    (once it's up)"
        return
    fi

    local device_id gui_addr hostname
    # v2 uses subcommand `device-id`, v1 used flag `--device-id`
    device_id=$(syncthing device-id 2>/dev/null || syncthing --device-id 2>/dev/null || echo "unknown")
    # Extract address from inside <gui>...</gui> only — the first <address> in the
    # file may belong to a <device> block (where it can be "dynamic")
    gui_addr=$(awk '/<gui/,/<\/gui>/' "$config_path" \
        | grep -oE '<address>[^<]+</address>' \
        | head -1 \
        | sed -E 's|</?address>||g')
    [[ -z "$gui_addr" ]] && gui_addr="127.0.0.1:8384"
    hostname=$(hostname)

    echo ""
    echo -e "${GREEN}━━━ This node is up. Pair it from a peer: ━━━${NC}"
    echo ""
    echo -e "  Hostname:   ${BLUE}$hostname${NC}"
    echo -e "  Device ID:  ${BLUE}$device_id${NC}"
    echo -e "  Web UI:     ${BLUE}http://$gui_addr${NC}"
    echo ""
    echo "  On a peer (e.g. your Hetzner node) → Web UI → Add Remote Device →"
    echo "  paste the Device ID, then share the 'notes-vault' folder with it."
    echo ""
}

main() {
    echo "🔗 join-notes-mesh"
    echo ""

    local os
    os=$(detect_os)
    echo "Detected OS: $os"
    echo ""

    require_pkg_manager "$os"
    install_syncthing "$os"
    create_vault
    start_syncthing "$os"
    print_join_info "$os"
}

main "$@"
