# Stow package lists.
# - STOW_PACKAGES + STOW_PACKAGES_{MACOS,LINUX,SWAY,OMARCHY}: sourced by install.sh,
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
# colours and borders, waybar, lock screen, GTK dark mode.
STOW_PACKAGES_SWAY=(
    "sway"
)

# Only stowed on Omarchy. Holds the Hyprland keybinding overrides that load
# after Omarchy's defaults.
STOW_PACKAGES_OMARCHY=(
    "hypr"
)

STOW_PACKAGES_DEVCONTAINER=(
    "bash"
    "bat"
    "git"
    "lazygit"
    "nvim"
    "shell"
)
