#!/usr/bin/env bash
# Make a laptop hibernate after it has been asleep with the lid closed:
#   lid close suspends, and 10 minutes later the machine hibernates.
# Suspend alone keeps drawing power (about 1% per hour on a Framework 13),
# and a machine that wakes itself in a bag can run the battery flat.
# Idempotent: re-running is safe and only changes what is out of spec.
# Supported: Linux laptops with systemd-logind and working hibernation.
# Run with: ~/dotfiles/scripts/setup-lid-hibernate.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOGIND_DROP_IN="/etc/systemd/logind.conf.d/30-lid-hibernate.conf"
SLEEP_DROP_IN="/etc/systemd/sleep.conf.d/10-hibernate-delay.conf"

# Guards
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${YELLOW}skip${NC}: not Linux (this script targets Linux with systemd-logind)"
    exit 0
fi

for cmd in systemctl install cmp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} required command not found: $cmd"
        exit 1
    fi
done

if ! compgen -G "/proc/acpi/button/lid/*/state" >/dev/null; then
    echo -e "${YELLOW}skip${NC}: no lid switch found (not a laptop)"
    exit 0
fi

# Without working hibernation logind refuses the lid action outright, which
# would leave the laptop awake with the lid closed.
if [[ " $(cat /sys/power/state 2>/dev/null) " != *" disk "* ]] ||
    ! grep -qE '(^| )resume=' /proc/cmdline; then
    echo -e "${YELLOW}skip${NC}: hibernation is not set up on this machine"
    exit 0
fi

echo "Applying lid-close hibernate on $(hostname)..."

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

write_drop_in "$LOGIND_DROP_IN" "[Login]
HandleLidSwitch=suspend-then-hibernate"

write_drop_in "$SLEEP_DROP_IN" "[Sleep]
HibernateDelaySec=10min"

# Reload logind in place. Restarting it would end the running desktop session.
if (( CHANGED == 1 )); then
    echo -e "${YELLOW}→${NC} reloading systemd-logind"
    sudo systemctl kill -s HUP systemd-logind
fi

echo -e "${GREEN}✓${NC} lid close suspends, then hibernates after 10 minutes"
