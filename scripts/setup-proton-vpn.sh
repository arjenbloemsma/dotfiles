#!/usr/bin/env bash
# Install this host's Proton VPN WireGuard config.
# Pulls it from Vaultwarden with rbw and writes /etc/wireguard/proton.conf.
# Proton's DNS line is dropped so the host keeps the resolvers set by
# setup-system-dns.sh.
# Idempotent — re-running is safe and only changes what is out of spec.
# Run with: ~/dotfiles/scripts/setup-proton-vpn.sh
# Then bring the tunnel up with: sudo wg-quick up proton

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ITEM="proton-wireguard-$(hostname -s)"
CONF_PATH="/etc/wireguard/proton.conf"

# Tailscale keeps its routes in table 52 and adds its rules at priority 5210.
# wg-quick sets no priority of its own, so the kernel places its rules just
# above whatever already exists. When Tailscale is already running that lands
# above it, and tailnet traffic ends up in the tunnel. These rules claim
# tailnet destinations first, whatever the start order.
TAILNET_RULES=(
    "PostUp = ip rule add to 100.64.0.0/10 lookup 52 priority 5000"
    "PostUp = ip -6 rule add to fd7a:115c:a1e0::/48 lookup 52 priority 5000 || true"
    "PostDown = ip rule del to 100.64.0.0/10 lookup 52 priority 5000 || true"
    "PostDown = ip -6 rule del to fd7a:115c:a1e0::/48 lookup 52 priority 5000 || true"
)

# The config has no IPv6, so IPv6 would go around the tunnel and show the
# real address. This route blocks it and programs fall back to IPv4 at once.
# Tailnet IPv6 still works, its rule is read first. Remove when the config
# carries IPv6 again.
IPV6_BLACKHOLE_RULES=(
    "PostUp = ip -6 route add blackhole default metric 1 || true"
    "PostDown = ip -6 route del blackhole default metric 1 || true"
)

if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${YELLOW}skip${NC}: not Linux"
    exit 0
fi

for cmd in rbw wg-quick install cmp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} required command not found: $cmd"
        exit 1
    fi
done

if ! rbw unlocked >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} rbw is locked; run: rbw unlock"
    exit 1
fi

echo "Installing Proton VPN config on $(hostname -s) from vault item $ITEM..."

TMP=$(mktemp)
RAW=$(mktemp)
chmod 600 "$TMP" "$RAW"
trap 'rm -f "$TMP" "$RAW"' EXIT

# Drop the context note the vault helper appends after a --- separator,
# then Proton's DNS line, then the IPv6 parts, then blank lines.
#
# IPv6 in the tunnel worked on 2026-08-25 and broke on the 26th. Tested
# NL#848 and NL#915, both fail, so it is Proton's side. The tunnel still
# gave out an IPv6 address, so programs tried IPv6 and hung. Drop the second
# sed and the blackhole rules above when Proton fixes it.
rbw get "$ITEM" \
    | sed '/^---$/,$d' \
    | grep -vE '^[[:space:]]*DNS[[:space:]]*=' \
    | sed -E '/^[[:space:]]*(Address|AllowedIPs)[[:space:]]*=/ s#,[[:space:]]*[0-9a-fA-F:]+:[0-9a-fA-F:]*(/[0-9]+)?##g' \
    | grep -vE '^[[:space:]]*$' > "$RAW"

# Add the tailnet and blackhole rules to the end of the [Interface] section.
{
    sed '/^\[Peer\]/,$d' "$RAW"
    printf '%s\n' "${TAILNET_RULES[@]}"
    printf '%s\n' "${IPV6_BLACKHOLE_RULES[@]}"
    sed -n '/^\[Peer\]/,$p' "$RAW"
} > "$TMP"

for section in '\[Interface\]' '\[Peer\]' 'PrivateKey' 'Endpoint'; do
    if ! grep -qE "^$section" "$TMP"; then
        echo -e "${RED}✗${NC} vault item does not look like a WireGuard config (missing $section)"
        exit 1
    fi
done

if sudo cmp -s "$TMP" "$CONF_PATH" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} already up to date: $CONF_PATH"
else
    echo -e "${YELLOW}→${NC} writing $CONF_PATH"
    sudo install -D -m 600 -o root -g root "$TMP" "$CONF_PATH"
    if wg show proton >/dev/null 2>&1; then
        echo -e "${YELLOW}→${NC} tunnel is running with the old config; restart it:"
        echo "    sudo wg-quick down proton && sudo wg-quick up proton"
    fi
fi

echo
echo -e "${GREEN}✓${NC} bring the tunnel up with: sudo wg-quick up proton"
