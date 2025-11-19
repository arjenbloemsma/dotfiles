# Neovim Config

LazyVim-based configuration, migrated from custom setup.

## Why LazyVim?

Switched from fully custom nvim config to LazyVim to reduce maintenance overhead. Previous setup required constant updates when packages changed, sometimes causing nested dependency issues that took significant time to resolve. LazyVim handles this complexity.

## Philosophy

- **Trying to stay close to LazyVim conventions** - minimal customization
- **Adopt LazyVim keymaps** - avoid custom keymaps, only use when required by personal workflow
- **Only customize what's necessary to comply with personal workflow**

Full details: [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md)

## Installation

```bash
cd ~/dotfiles
stow nvim
```

## Resources

- [LazyVim Docs](https://lazyvim.org)
- [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md) - All customizations with rationale
