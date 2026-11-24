#!/usr/bin/env bash
# Power a laptop off cleanly when the battery runs low:
#   warn at 20%, critical at 10%, power off at 5%.
# UPower's stock policy acts at 2% with CriticalPowerAction=Auto. Without a
# working hibernation setup that ends in a plain suspend, which only lasts
# minutes and then loses the session when the battery dies (fuji, 2026-11-23).
# Idempotent: re-running is safe and only changes what is out of spec.
# Supported: Linux laptops running UPower.
# Run with: ~/dotfiles/scripts/setup-low-battery-poweroff.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

UPOWER_DROP_IN="/etc/UPower/UPower.conf.d/50-low-battery-poweroff.conf"

# Guards
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${YELLOW}skip${NC}: not Linux (this script targets UPower on Linux)"
    exit 0
fi

for cmd in systemctl install cmp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} required command not found: $cmd"
        exit 1
    fi
done

if ! compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
    echo -e "${YELLOW}skip${NC}: no battery found (not a laptop)"
    exit 0
fi

# The drop-in directory only exists when UPower is installed and new enough
# (1.90.x or later) to read it.
if [[ ! -d /etc/UPower/UPower.conf.d ]]; then
    echo -e "${YELLOW}skip${NC}: UPower drop-in directory not found (UPower missing or too old)"
    exit 0
fi

echo "Applying low-battery power-off on $(hostname)..."

# Write a drop-in when it differs from what is on disk. Sets CHANGED=1 on write.
CHANGED=0
write_drop_in() {
    local path="$1" content="$2" tmp
    tmp=$(mktemp)
    printf '%s\n' "$content" > "$tmp"
    if sudo cmp -s "$tmp" "$path" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} drop-in already up to date: $path"
    else
        echo -e "${YELLOW}→${NC} writing $path"
        sudo install -D -m 644 -o root -g root "$tmp" "$path"
        CHANGED=1
    fi
    rm -f "$tmp"
}

# UPower needs low > critical > action, or it falls back to its defaults.
write_drop_in "$UPOWER_DROP_IN" "[UPower]
PercentageLow=20.0
PercentageCritical=10.0
PercentageAction=5.0
CriticalPowerAction=PowerOff"

# try-restart leaves UPower stopped if it was not running; D-Bus starts it
# later with the new settings.
if (( CHANGED == 1 )); then
    echo -e "${YELLOW}→${NC} restarting upower"
    sudo systemctl try-restart upower
fi

echo -e "${GREEN}✓${NC} the laptop powers off at 5% battery"
