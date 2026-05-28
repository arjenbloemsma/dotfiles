#!/usr/bin/env bash
# Stow the dotfiles packages relevant inside a devcontainer.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/stow-packages.sh"

command -v stow >/dev/null 2>&1 \
    || { echo -e "${RED}✗${NC} stow not installed in container" >&2; exit 1; }
command -v git >/dev/null 2>&1 \
    || { echo -e "${RED}✗${NC} git not installed in container" >&2; exit 1; }

echo "Stowing devcontainer packages..."
cd "$DOTFILES_DIR"

for pkg in "${STOW_PACKAGES_DEVCONTAINER[@]}"; do
    if [[ ! -d "$pkg" ]]; then
        echo -e "${YELLOW}⚠${NC} $pkg directory not found, skipping"
        continue
    fi
    # Base container images often ship default dotfiles. Drop any existing
    # target so stow doesn't fail; container state is disposable.
    while IFS= read -r -d '' rel; do
        rm -f "$HOME/$rel"
    done < <(git -C "$DOTFILES_DIR/$pkg" ls-files -z)
    stow --target="$HOME" --restow "$pkg"
    echo -e "${GREEN}✓${NC} $pkg"
done

echo -e "${GREEN}✓${NC} Devcontainer dotfiles installed"
