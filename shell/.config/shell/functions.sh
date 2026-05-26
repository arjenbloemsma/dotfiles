# Shell-agnostic functions — sourced by both .zshrc and .bashrc.

# Load a tool's shell init only if the tool is present
check_and_load() {
    local cmd="$1"
    local init_cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        eval "$init_cmd"
    else
        echo "⚠️  $cmd not found - skipping initialization"
    fi
}

# Yazi wrapper: cd into the directory Yazi was in when it quit
yy() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
