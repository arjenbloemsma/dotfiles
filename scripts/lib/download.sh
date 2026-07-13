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

# Download a zip and extract a single executable entry into a directory, then
# make it executable. For tools shipped as zips rather than raw binaries.
# Creates the directory if missing.
download_zipped_binary() {
    local url="$1"
    local entry="$2"
    local dest_dir="$3"
    mkdir -p "$dest_dir"
    local tmp
    tmp="$(mktemp -d)"
    curl -fL --progress-bar -o "$tmp/pkg.zip" "$url"
    unzip -oq "$tmp/pkg.zip" "$entry" -d "$dest_dir"
    chmod +x "$dest_dir/$entry"
    rm -rf "$tmp"
}
