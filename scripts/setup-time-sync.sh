#!/usr/bin/env bash
# Point chrony at NTS-capable time servers:
#   nts.time.nl (SIDN), nts.netnod.se (Netnod).
# The Fedora default (pool 2.fedora.pool.ntp.org ... nts) never syncs,
# because pool servers do not offer NTS.
# Without chrony, systemd-timesyncd gets the same providers over plain NTP,
# since it has no NTS.
# Idempotent: re-running is safe and only changes what is out of spec.
# Supported: any Linux-based system running chronyd or systemd-timesyncd,
# including immutable / atomic variants.
# Run with: ~/dotfiles/scripts/setup-time-sync.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONF_PATH="/etc/chrony.conf"
SERVERS=(nts.time.nl nts.netnod.se)
MARKER="# Managed by dotfiles scripts/setup-time-sync.sh"
# Sorts after the distro's own drop-in, so its FallbackNTP is replaced
TIMESYNCD_DROP_IN="/etc/systemd/timesyncd.conf.d/20-time-servers.conf"

# Guards
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${YELLOW}skip${NC}: not Linux (this script targets Linux with chronyd or timesyncd)"
    exit 0
fi

if ! command -v chronyc >/dev/null 2>&1 && systemctl is-active --quiet systemd-timesyncd; then
    echo "Applying time servers to systemd-timesyncd on $(hostname)..."
    TMP_CONF=$(mktemp)
    printf '%s\n[Time]\nNTP=ntp.time.nl\nFallbackNTP=ntp.netnod.se\n' "$MARKER" > "$TMP_CONF"
    if cmp -s "$TMP_CONF" "$TIMESYNCD_DROP_IN"; then
        echo -e "${GREEN}✓${NC} $TIMESYNCD_DROP_IN already up to date"
    else
        echo -e "${YELLOW}→${NC} writing $TIMESYNCD_DROP_IN"
        sudo install -D -m 644 -o root -g root "$TMP_CONF" "$TIMESYNCD_DROP_IN"
        echo -e "${YELLOW}→${NC} restarting systemd-timesyncd"
        sudo systemctl restart systemd-timesyncd
    fi
    rm -f "$TMP_CONF"
    echo -e "${GREEN}✓${NC} check the server with: timedatectl timesync-status"
    exit 0
fi

if [[ ! -f "$CONF_PATH" ]] || ! command -v chronyc >/dev/null 2>&1; then
    echo -e "${YELLOW}skip${NC}: chrony not installed"
    exit 0
fi

echo "Applying NTS time servers on $(hostname)..."

# 1. Config: our server lines first, every other pool/server line removed
TMP_CONF=$(mktemp)
{
    echo "$MARKER"
    for server in "${SERVERS[@]}"; do
        echo "server $server iburst nts"
    done
    grep -vxF "$MARKER" "$CONF_PATH" | grep -vE '^(pool|server)[[:space:]]' || true
} > "$TMP_CONF"

if cmp -s "$TMP_CONF" "$CONF_PATH"; then
    echo -e "${GREEN}✓${NC} $CONF_PATH already up to date"
else
    echo -e "${YELLOW}→${NC} writing $CONF_PATH"
    # cp onto the existing file keeps its mode and SELinux label
    sudo cp "$TMP_CONF" "$CONF_PATH"
    echo -e "${YELLOW}→${NC} restarting chronyd"
    sudo systemctl restart chronyd
fi
rm -f "$TMP_CONF"

# 2. Verify: wait up to 60s for a sync; no network during install is not fatal
if chronyc -N waitsync 12 0 0 5 >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} clock synchronised"
else
    echo -e "${YELLOW}⚠${NC} not synchronised yet; check with: chronyc -N sources"
fi

echo
echo -e "${GREEN}✓${NC} NTS sources:"
sudo chronyc -N authdata | sed 's/^/    /'
