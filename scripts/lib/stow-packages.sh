# Stow package lists.
# - STOW_PACKAGES + STOW_PACKAGES_{MACOS,LINUX,SWAY}: sourced by install.sh,
#   stow onto the host.
# - STOW_PACKAGES_DEVCONTAINER: sourced by scripts/devcontainer-install.sh,
#   stow inside a devpod container via devpod's dotfiles hook.

STOW_PACKAGES=(
    "bat"
    "claude"
    "git"
    "nvim"
    "podman"
    "sesh"
    "shell"
    "starship"
    "tmux"
    "yazi"
)

STOW_PACKAGES_MACOS=(
    "ghostty"
    "skhd"
    "yabai"
    "zsh"
)

STOW_PACKAGES_LINUX=(
    "bash"
)

# Only stowed when sway is installed. Holds the sway session look: window
# colours and borders, waybar, lock screen.
STOW_PACKAGES_SWAY=(
    "sway"
)

STOW_PACKAGES_DEVCONTAINER=(
    "bash"
    "bat"
    "git"
    "lazygit"
    "nvim"
    "shell"
)
