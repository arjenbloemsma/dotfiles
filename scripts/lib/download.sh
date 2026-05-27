# Shared download helpers. Sourced by install.sh.

# Download a binary to a target path with a progress bar, then make it executable.
# Creates the parent dir if missing.
download_binary() {
    local url="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    curl -fL --progress-bar -o "$target" "$url"
    chmod +x "$target"
}
