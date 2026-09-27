#!/usr/bin/env bash
# Give the SDDM greeter the dark wallpaper.
# The Fedora sway theme ships in /usr, which is read-only on Atomic, so the
# theme is copied to /etc/sddm/themes and SDDM is pointed at that copy.
# Idempotent, re-running is safe and only changes what is out of spec.
# Run with: ~/dotfiles/scripts/setup-sddm-theme.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

THEME="03-sway-fedora"
SRC="/usr/share/sddm/themes/$THEME"
DEST_DIR="/etc/sddm/themes"
DEST="$DEST_DIR/$THEME"
CONF="/etc/sddm.conf.d/10-theme.conf"
BACKGROUND="/usr/share/backgrounds/images/default-dark.jxl"

if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${YELLOW}skip${NC}: not Linux"
    exit 0
fi

if [[ ! -d "$SRC" ]]; then
    echo -e "${YELLOW}skip${NC}: SDDM theme not found: $SRC"
    exit 0
fi

if [[ ! -f "$BACKGROUND" ]]; then
    echo -e "${RED}✗${NC} wallpaper not found: $BACKGROUND"
    exit 1
fi

for cmd in install cmp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} required command not found: $cmd"
        exit 1
    fi
done

echo "Setting the SDDM greeter background on $(hostname -s)..."

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# 1. Theme copy. Only the background differs from upstream, so the copy is
# refreshed whenever the theme's own files change.
if [[ ! -d "$DEST" ]]; then
    echo -e "${YELLOW}→${NC} copying $THEME to $DEST_DIR"
    sudo mkdir -p "$DEST_DIR"
    sudo cp -r "$SRC" "$DEST_DIR/"
else
    echo -e "${GREEN}✓${NC} theme copy already present: $DEST"
fi

# 2. Background. Overwrites the theme.conf that came with the copy.
printf '[General]\nbackground=%s\n' "$BACKGROUND" > "$TMP"
if sudo cmp -s "$TMP" "$DEST/theme.conf" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} background already set"
else
    echo -e "${YELLOW}→${NC} writing $DEST/theme.conf"
    sudo install -m 644 -o root -g root "$TMP" "$DEST/theme.conf"
fi

# 3. Point SDDM at the copy. ThemeDir replaces the search path, so SDDM reads
# themes from /etc only.
printf '[Theme]\nThemeDir=%s\nCurrent=%s\n' "$DEST_DIR" "$THEME" > "$TMP"
if sudo cmp -s "$TMP" "$CONF" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} already up to date: $CONF"
else
    echo -e "${YELLOW}→${NC} writing $CONF"
    sudo install -D -m 644 -o root -g root "$TMP" "$CONF"
fi

echo
echo -e "${GREEN}✓${NC} the greeter picks this up at the next log out"
