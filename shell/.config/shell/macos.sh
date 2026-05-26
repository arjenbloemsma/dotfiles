# macOS-specific shell setup.

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Homebrew curl ahead of the system one
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# Brew upgrade includes greedy casks (Firefox, Raycast, ...) on plain `brew upgrade`
export HOMEBREW_UPGRADE_GREEDY=1
