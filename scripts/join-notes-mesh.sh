#!/usr/bin/env bash
#
# Join this machine to the notes-vault syncthing mesh.
#
# - Installs syncthing if missing (native package manager only, no brew on Linux)
# - Creates ~/notes-vault
# - Starts syncthing as a user service
# - Reads peer list from notes-mesh.conf.local (or NOTES_MESH_PEERS_ENV var)
# - Adds each peer as a remote device and shares notes-vault with each
# - Prints device ID + Web UI URL so a peer can accept the pairing
#
# Safe to re-run. Works on macOS (requires brew), Debian/Ubuntu, Arch, Fedora.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/notes-mesh.conf.local"
VAULT_DIR="$HOME/notes-vault"

# Defaults — overridable in conf file
NOTES_FOLDER_ID="notes-vault"
NOTES_FOLDER_LABEL="notes-vault"
NOTES_MESH_PEERS=()

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

# Load peers from conf file or env var. Env var wins.
# Conf file format documented in notes-mesh.conf.template.
# Env format: comma-separated "ID|name" entries.
load_peers() {
    if [[ -n "${NOTES_MESH_PEERS_ENV:-}" ]]; then
        IFS=',' read -r -a NOTES_MESH_PEERS <<< "$NOTES_MESH_PEERS_ENV"
        echo -e "${GREEN}✓${NC} loaded ${#NOTES_MESH_PEERS[@]} peer(s) from NOTES_MESH_PEERS_ENV"
        return
    fi

    if [[ -f "$CONF_FILE" ]]; then
        # shellcheck disable=SC1090
        . "$CONF_FILE"
        if (( ${#NOTES_MESH_PEERS[@]} == 0 )); then
            echo -e "${RED}✗${NC} $CONF_FILE has no peers"
            exit 1
        fi
        echo -e "${GREEN}✓${NC} loaded ${#NOTES_MESH_PEERS[@]} peer(s) from $(basename "$CONF_FILE")"
        return
    fi

    echo -e "${RED}✗${NC} no peer config found"
    echo "   create $CONF_FILE (copy from notes-mesh.conf.template)"
    echo "   or set NOTES_MESH_PEERS_ENV=\"id1|name1,id2|name2\""
    exit 1
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

# Wait until the local syncthing REST API answers — the CLI talks to it,
# so a successful list call confirms config + GUI are both ready.
wait_for_api() {
    local tries=30
    while (( tries-- > 0 )); do
        if syncthing cli config devices list >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} syncthing API reachable"
            return 0
        fi
        sleep 1
    done
    echo -e "${RED}✗${NC} syncthing API never came up"
    exit 1
}

# Idempotently add each peer as a remote device, ensure the notes-vault
# folder exists, and share it with each peer. No introducer flag —
# trust is granted explicitly per peer.
apply_mesh_config() {
    local existing_devices existing_folders existing_folder_devices entry id name

    existing_devices=$(syncthing cli config devices list 2>/dev/null || true)

    for entry in "${NOTES_MESH_PEERS[@]}"; do
        id="${entry%%|*}"
        name="${entry##*|}"
        if grep -qx "$id" <<< "$existing_devices"; then
            echo -e "${GREEN}✓${NC} peer already known: $name"
        else
            syncthing cli config devices add --device-id "$id" --name "$name"
            echo -e "${GREEN}✓${NC} added peer: $name"
        fi
    done

    existing_folders=$(syncthing cli config folders list 2>/dev/null || true)
    if grep -qx "$NOTES_FOLDER_ID" <<< "$existing_folders"; then
        echo -e "${GREEN}✓${NC} folder already exists: $NOTES_FOLDER_ID"
    else
        syncthing cli config folders add \
            --id "$NOTES_FOLDER_ID" \
            --label "$NOTES_FOLDER_LABEL" \
            --path "$VAULT_DIR"
        echo -e "${GREEN}✓${NC} added folder: $NOTES_FOLDER_ID"
    fi

    existing_folder_devices=$(syncthing cli config folders "$NOTES_FOLDER_ID" devices list 2>/dev/null || true)
    for entry in "${NOTES_MESH_PEERS[@]}"; do
        id="${entry%%|*}"
        name="${entry##*|}"
        if grep -qx "$id" <<< "$existing_folder_devices"; then
            echo -e "${GREEN}✓${NC} folder already shared with: $name"
        else
            syncthing cli config folders "$NOTES_FOLDER_ID" devices add --device-id "$id"
            echo -e "${GREEN}✓${NC} shared folder with: $name"
        fi
    done
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

    local device_id gui_addr hostname
    device_id=$(syncthing device-id 2>/dev/null || syncthing --device-id 2>/dev/null || echo "unknown")
    gui_addr=$(awk '/<gui/,/<\/gui>/' "$config_path" \
        | grep -oE '<address>[^<]+</address>' \
        | head -1 \
        | sed -E 's|</?address>||g')
    [[ -z "$gui_addr" ]] && gui_addr="127.0.0.1:8384"
    hostname=$(hostname)

    echo ""
    echo -e "${GREEN}━━━ This node is configured. Two clicks remain on each peer: ━━━${NC}"
    echo ""
    echo -e "  Hostname:   ${BLUE}$hostname${NC}"
    echo -e "  Device ID:  ${BLUE}$device_id${NC}"
    echo -e "  Web UI:     ${BLUE}http://$gui_addr${NC}"
    echo ""
    echo "  On each peer's web UI:"
    echo "    1. Accept the 'New Device' prompt for this hostname"
    echo "    2. Accept the 'New Folder' prompt to share notes-vault back"
    echo ""
    echo "  Then notes-vault syncs automatically."
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
    load_peers
    install_syncthing "$os"
    create_vault
    start_syncthing "$os"
    wait_for_api
    apply_mesh_config
    print_join_info "$os"
}

main "$@"
