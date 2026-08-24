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

# Proton's config sends everything through the tunnel, including traffic meant
# for the tailnet, so Tailscale stops working. WireGuard cannot say "everything
# except this", so the lists below spell out everything apart from Tailscale's
# addresses: 100.64.0.0/10 and the private fd00::/8 block that holds
# fd7a:115c:a1e0::/48.
# https://tailscale.com/kb/1033/ip-and-dns-addresses
ALLOWED_V4="0.0.0.0/2, 64.0.0.0/3, 96.0.0.0/6, 100.0.0.0/10, 100.128.0.0/9, 101.0.0.0/8, 102.0.0.0/7, 104.0.0.0/5, 112.0.0.0/4, 128.0.0.0/1"
ALLOWED_V6="::/1, 8000::/2, c000::/3, e000::/4, f000::/5, f800::/6, fc00::/8, fe00::/7"

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
chmod 600 "$TMP"
trap 'rm -f "$TMP"' EXIT

# Drop the context note the vault helper appends after a --- separator, then
# Proton's DNS line, then blank lines, then replace AllowedIPs so the tunnel
# leaves the tailnet alone.
rbw get "$ITEM" \
    | sed '/^---$/,$d' \
    | grep -vE '^[[:space:]]*DNS[[:space:]]*=' \
    | grep -vE '^[[:space:]]*$' \
    | sed -E "s#^[[:space:]]*AllowedIPs[[:space:]]*=.*#AllowedIPs = ${ALLOWED_V4}, ${ALLOWED_V6}#" > "$TMP"

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
