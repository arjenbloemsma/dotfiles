# Fedora-specific shell setup.

# Source the system-wide bashrc (locale, /etc/profile.d/*, completions).
[[ -f /etc/bashrc ]] && source /etc/bashrc

# Ensure personal bin dirs are on PATH (Fedora 44 OOTB .bashrc adds these; we replace it).
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":$HOME/bin:"*) ;; *) export PATH="$HOME/bin:$PATH" ;; esac
