#!/usr/bin/env bash
# Point chrony at NTS-capable time servers:
#   nts.time.nl (SIDN), nts.netnod.se (Netnod).
# The Fedora default (pool 2.fedora.pool.ntp.org ... nts) never syncs,
# because pool servers do not offer NTS.
# Idempotent: re-running is safe and only changes what is out of spec.
# Supported: any Linux-based system running chronyd,
# including immutable / atomic variants.
# Run with: ~/dotfiles/scripts/setup-time-sync.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONF_PATH="/etc/chrony.conf"
SERVERS=(nts.time.nl nts.netnod.se)
MARKER="# Managed by dotfiles scripts/setup-time-sync.sh"

# Guards
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${YELLOW}skip${NC}: not Linux (this script targets Linux with chronyd)"
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
