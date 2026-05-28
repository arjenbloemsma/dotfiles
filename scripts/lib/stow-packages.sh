# Stow package lists.
# - STOW_PACKAGES + STOW_PACKAGES_{MACOS,LINUX}: sourced by install.sh, stow
#   onto the host.
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

STOW_PACKAGES_DEVCONTAINER=(
    "bash"
    "bat"
    "git"
    "lazygit"
    "nvim"
    "shell"
)
