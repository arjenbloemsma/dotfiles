#!/usr/bin/env bash
# Apply privacy-respecting DNS resolvers:
#   Quad9 (9.9.9.9, 149.112.112.112).
# Strips DHCP-supplied DNS from every NetworkManager ethernet + wifi
# connection so the ISP cannot inject its own resolvers.
# Idempotent — re-running is safe and only changes what is out of spec.
# Supported: any Linux-based system with systemd-resolved + NetworkManager,
# including immutable / atomic variants.
# Run with: ~/dotfiles/scripts/setup-system-dns.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DROP_IN_PATH="/etc/systemd/resolved.conf.d/00-quad9.conf"

# Guards
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${YELLOW}skip${NC}: not Linux (this script targets Linux with systemd-resolved + NetworkManager)"
    exit 0
fi

for cmd in nmcli systemctl install cmp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} required command not found: $cmd"
        exit 1
    fi
done

if ! systemctl is-active --quiet systemd-resolved; then
    echo -e "${RED}✗${NC} systemd-resolved is not active; refusing to proceed"
    exit 1
fi

echo "Applying Quad9 DNS on $(hostname)..."

# 1. Drop-in file
TMP_DROP_IN=$(mktemp)
cat > "$TMP_DROP_IN" <<'EOF'
[Resolve]
DNS=9.9.9.9 149.112.112.112
FallbackDNS=
EOF

DROP_IN_CHANGED=0
if sudo cmp -s "$TMP_DROP_IN" "$DROP_IN_PATH" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} drop-in already up to date: $DROP_IN_PATH"
else
    echo -e "${YELLOW}→${NC} writing $DROP_IN_PATH"
    sudo install -D -m 644 "$TMP_DROP_IN" "$DROP_IN_PATH"
    DROP_IN_CHANGED=1
fi
rm -f "$TMP_DROP_IN"

# 2. NetworkManager connections: ignore DHCP-supplied DNS on every wired + wifi profile
CHANGED_ACTIVE_UUIDS=()
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    conn_uuid="${line%%:*}"
    conn_name="${line#*:}"
    conn_type=$(nmcli -t -f connection.type connection show "$conn_uuid" | cut -d: -f2)
    if [[ "$conn_type" != "802-3-ethernet" && "$conn_type" != "802-11-wireless" ]]; then
        continue
    fi
    ipv4_state=$(nmcli -t -f ipv4.ignore-auto-dns connection show "$conn_uuid" | cut -d: -f2)
    ipv6_state=$(nmcli -t -f ipv6.ignore-auto-dns connection show "$conn_uuid" | cut -d: -f2)
    if [[ "$ipv4_state" == "yes" && "$ipv6_state" == "yes" ]]; then
        echo -e "${GREEN}✓${NC} connection '$conn_name' already ignores DHCP DNS"
        continue
    fi
    echo -e "${YELLOW}→${NC} connection '$conn_name': setting ignore-auto-dns"
    sudo nmcli connection modify "$conn_uuid" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes
    if nmcli -t -f UUID connection show --active | grep -qx "$conn_uuid"; then
        CHANGED_ACTIVE_UUIDS+=("$conn_uuid|$conn_name")
    fi
done < <(nmcli -t -f UUID,NAME connection show)

# 3. Apply: restart systemd-resolved if drop-in changed, bounce active changed connections
if (( DROP_IN_CHANGED == 1 )); then
    echo -e "${YELLOW}→${NC} restarting systemd-resolved"
    sudo systemctl restart systemd-resolved
fi

for entry in "${CHANGED_ACTIVE_UUIDS[@]:-}"; do
    [[ -z "$entry" ]] && continue
    uuid="${entry%%|*}"
    name="${entry#*|}"
    echo -e "${YELLOW}→${NC} bouncing active connection '$name' to apply ignore-auto-dns"
    sudo nmcli connection up uuid "$uuid" >/dev/null
done

echo
echo -e "${GREEN}✓${NC} effective DNS:"
grep -E '^(nameserver|search)' /run/systemd/resolve/resolv.conf | sed 's/^/    /'
