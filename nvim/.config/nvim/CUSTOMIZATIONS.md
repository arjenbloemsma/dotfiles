# LazyVim Customizations

This document tracks all customizations made to the LazyVim starter config and reasoning behind them.

## Overview

- **Base**: LazyVim starter (fresh install)
- **Old config**: Custom bloem namespace configuration
- **Migration date**: 2025-11-08

---

## Plugins Added

### 1. Catppuccin Theme (`colorscheme.lua`)
**Why**: Personal preference for Catppuccin Mocha theme
**Features**:
- Transparent background for see-through terminal
- Italic comments, conditionals, functions
- All LazyVim integrations enabled

**Replaces**: LazyVim default theme
**Status**: ✅ Working

---

### 2. Zen Mode (built-in Snacks.nvim)
**Why**: Ergonomic centered coding view, reduces eye strain
**Keymap**: `<leader>uz` - Toggle zen mode (LazyVim default)
**Config**: 120 character width, dimmed backdrop
**Status**: ✅ Using LazyVim built-in

**Note**: Previously used no-neck-pain.nvim, removed 2025-12-04 in favor of
built-in Snacks.zen which provides same functionality with better integration.

**Related**: `<leader>uZ` - Zoom mode (fullscreen current split, keeps statusline)

---

### 3. ~~Obsidian.nvim~~ (removed 2026-04-25)
**Why removed**: No longer using Obsidian. All functionality replaced by custom plugins:
- **todo.lua** - Checkbox toggling (`<leader>td`, `<leader>tc`)
- **daily-notes.lua** - Daily notes (`<leader>nt`, `<leader>ny`)
- **custom-zettelkasten.lua** - Tag search (`<leader>zt`), enhanced `gf`

---

### 4. Todo Management (`todo.lua`)
**Why**: Markdown checkbox management without obsidian.nvim dependency

**Keymaps**:
- `<leader>td` - Toggle checkbox (`[ ]` ↔ `[x]`)
- `<leader>tc` - Convert line(s) to todo

**Convert behavior**:
- `- item` → `- [ ] item`
- `* item` → `- [ ] * item`
- `1. item` → `- [ ] 1. item`
- `plain text` → `- [ ] plain text`

**Visual mode**: Works on multiple selected lines
**Status**: ✅ Working

---

### 5. Daily Notes (`daily-notes.lua`)
**Why**: Quick daily note access without obsidian.nvim dependency
**Vault**: Read from `vim.g.NOTES_VAULT` (set in `init.lua`)

**Keymaps**:
- `<leader>nt` - Open today's note
- `<leader>ny` - Open yesterday's note

**Features**:
- Creates note from template if it doesn't exist
- Notes stored in `dailies/YYYY-MM-DD.md`

**Status**: ✅ Working

---

### 6. LazyGit (`lazygit.lua`)
**Why**: Git UI inside nvim without leaving editor
**Keymap**: `<leader>lg` - Open LazyGit
**Features**:
- Stage/unstage files
- Make commits
- Push/pull
- View diffs
- All in floating window

**Replaces**: Manual terminal lazygit usage
**Status**: ✅ Working

---

### 7. Harpoon
**Why**: Quick file navigation (Prime's workflow)
**How added**: Via LazyVim extras menu
**Status**: ✅ Installed

---

### 8. Conform.nvim (`conform.lua`)
**Why**: Code formatting with prettier
**Formatters**:
- Markdown: prettier

**Status**: ✅ Working

---

### 9. Mason Tools (`mason.lua`)
**Why**: Explicit `ensure_installed` list so all tools install on first launch.
LazyVim extras only install Mason packages when the relevant filetype loads,
which means a fresh machine is missing tools until you open every filetype.

**LSPs**: bash-language-server, bicep-lsp, docker-compose-language-service,
dockerfile-language-server, json-lsp, lua-language-server, marksman,
svelte-language-server, tailwindcss-language-server, vtsls

**Linters**: hadolint, markdownlint-cli2, shellcheck

**Formatters**: prettier (markdown only), shfmt, stylua

**Dropped** (2026-04-27): typescript-language-server (replaced by vtsls),
tsgo (experimental), biome/oxlint/oxfmt (not yet migrated from eslint+prettier),
xmlformatter, markdown-toc, tree-sitter-cli

**Status**: ✅ Working

---

### 9. Lualine (`lualine.lua`)
**Why**: Simplified statusline for tmux workflow
**Customizations**:
- Removed current directory (redundant with tmux)
- Kept: diagnostics, filename (relative path), filetype, location, encoding
- Clean inactive sections

**Status**: ✅ Working

---

## Plugins Disabled (`lua/plugins/disabled.lua`)

### 1. Snacks Explorer & Dashboard
**Why**:
- Dashboard not needed
- Explorer disabled in favor of dual file browsing approach:
  - **Neo-tree**: Classic left sidebar navigation
  - **Mini.files**: Miller columns view (like macOS Finder)

**Keymaps unmapped**: `<leader>e`, `<leader>E`

### 2. Bufferline
**Why**: Tab bar at top not needed, prefer buffer list

### 3. Render-Markdown
**Why**: Sets conceallevel which hides TODO indicators like `[ ]`, `[X]`, breaks workflow

### 4. Mini.Pairs
**Why**: Auto-pairing of quotes/brackets/braces interferes with Vi typing flow
**Date disabled**: 2025-11-19

---

## Custom Options (`lua/config/options.lua`)

Settings that override LazyVim defaults:

```lua
vim.g.loaded_netrw = 1           -- Disable netrw (using neo-tree)
vim.g.loaded_netrwPlugin = 1     -- Disable netrw plugin
opt.mouse = ""                   -- Disable mouse (keyboard-only workflow)
opt.swapfile = false             -- No swap files
opt.scrolloff = 5                -- Keep 5 lines context above/below cursor
opt.colorcolumn = "80"           -- Visual guide at column 80
opt.wrap = false                 -- No line wrapping
opt.tabstop = 2                  -- 2-space indentation
opt.shiftwidth = 2               -- 2-space indentation
opt.expandtab = true             -- Expand tabs to spaces
opt.autoindent = true            -- Copy indent from current line
vim.g.snacks_animate = false     -- Disable snacks animations
vim.o.autoread = true            -- Auto-reload files modified externally
```

**Why**: Personal coding preferences, consistency with prettier defaults

---

## Custom Auto-commands (`lua/config/autocmds.lua`)

```lua
-- Auto-reload files when modified externally
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = "*",
  group = vim.api.nvim_create_augroup("auto-read", { clear = true }),
})

-- Set correct filetype for .env files (prevents shell LSP warnings)
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { ".env", ".env.*" },
  callback = function()
    vim.bo.filetype = "dotenv"
  end,
})
```

**Why**:
- Auto-reload prevents stale file issues when switching branches
- Dotenv filetype prevents bashls from analyzing .env files as shell scripts

---

## Custom Keymaps (`lua/config/keymaps.lua`)

Using LazyVim defaults only.

### Enhanced `gf` (`custom-zettelkasten.lua`)

**Why**: Native `gf` includes `#` in filename (it's in `isfname`), so
`file.md#heading` fails with E447. This override temporarily removes `#` from
`isfname`, lets native `gf` resolve the file, then jumps to the matching
markdown heading.

**How**: Wraps native `gf` — temporarily tweaks `isfname`, calls `normal! gf`,
restores `isfname`, searches for heading.

**Keymap**: `gf` (overrides built-in)
**Status**: ✅ Working (2026-02-14)

---

## What LazyVim Already Provides

These were in old config but **not needed** - LazyVim includes them:

### Plugins
- ✅ **telescope** - LazyVim uses fzf-lua instead (lighter, faster)
- ✅ **neo-tree** - Already included
- ✅ **which-key** - Already included
- ✅ **gitsigns** - Already included
- ✅ **nvim-cmp** - Already included (completion)
- ✅ **treesitter** - Already included
- ✅ **lualine** - Already included (status line)
- ✅ **copilot** - Available via LazyVim extras
- ✅ **alpha** - LazyVim has dashboard

### Settings
- ✅ **relativenumber** - LazyVim default
- ✅ **ignorecase/smartcase** - LazyVim default
- ✅ **cursorline** - LazyVim default

---

## Not Yet Migrated from Old Config

### Plugins

1. **ChatGPT.nvim**
   - Reason: AI integration with OpenAI
   - Keychain setup: `security find-generic-password -w -s OpenAI-API-key`
   - Status: 🔲 Not yet added
   - Decision needed: Still want this?

2. **vim-tmux-navigator**
   - Reason: Seamless vim/tmux pane navigation
   - Status: ✅ Added (2025-12-20)

3. **vim-maximizer**
   - Reason: Toggle window maximize
   - Keymap: `<leader>sm` in old config
   - Status: 🔲 Not yet added
   - Alternative: LazyVim has built-in window management

4. **oil.nvim**
   - Reason: File browser
   - Status: 🔲 Commented out in old config
   - Decision: Probably not needed (neo-tree covers this)

### Keymaps

Missing keymaps from old config:

```lua
-- Insert mode
"jk" -> "<ESC>"           -- Quick exit insert mode

-- Normal mode
"<leader>nh" -> ":nohl"   -- Clear search highlights
"<leader>+" -> increment  -- Increment number
"<leader>-" -> decrement  -- Decrement number

-- Visual mode
"J" -> move down          -- Move selected text down
"K" -> move up            -- Move selected text up

-- Window management
"<leader>sv" -> split vertical
"<leader>sh" -> split horizontal
"<leader>se" -> equal splits
"<leader>sx" -> close split
```

**Status**: 🔲 Not yet added
**Decision needed**: Which keymaps are critical to workflow?

### Auto-commands

From old config:

1. **YankHighlight** - Highlight on yank
   - Status: ❓ Check if LazyVim has this

2. **Auto-save** on BufLeave/FocusLost
   - Status: 🔲 Not migrated
   - Decision: Want auto-save?

3. **Auto-read** on focus gain
   - Status: 🔲 Not migrated

---

## File Structure

```
~/.config/nvim/
├── init.lua                      # ✨ Env var validation + LazyVim entry point
├── lua/
│   ├── config/
│   │   ├── options.lua           # ✨ Custom options override
│   │   ├── autocmds.lua          # ✨ Custom auto-commands
│   │   └── keymaps.lua           # LazyVim defaults
│   └── plugins/
│       ├── colorscheme.lua       # ✨ Catppuccin config
│       ├── todo.lua              # ✨ Checkbox toggle/convert
│       ├── daily-notes.lua       # ✨ Daily note navigation
│       ├── custom-zettelkasten.lua # ✨ Tag search + enhanced gf
│       ├── lazygit.lua           # ✨ Git UI
│       └── example.lua           # LazyVim examples
├── CUSTOMIZATIONS.md             # This file
└── [LazyVim default files...]
```

**✨** = Custom additions

---

## Decision Matrix

Use this to evaluate future customizations:

| Feature | Old Config | LazyVim | Action | Priority |
|---------|-----------|---------|--------|----------|
| Catppuccin theme | ✅ | ❌ | ✅ Added | High |
| Zen mode | ✅ | Snacks.zen | ✅ Using built-in | Medium |
| Obsidian | ✅ | ❌ | ✅ Removed | N/A |
| Todo keymaps | ❌ | ❌ | ✅ todo.lua | High |
| Daily notes | ❌ | ❌ | ✅ daily-notes.lua | High |
| LazyGit | ✅ | ❌ | ✅ Added | High |
| Harpoon | ✅ | Extra | ✅ Added | High |
| Tmux nav | ✅ | ❌ | ✅ Added | High |
| Telescope | ✅ | fzf-lua | ✅ Skip | N/A |
| ChatGPT | ✅ | ❌ | ✅ Skip | N/A (Claude Code) |
| Custom keymaps | ✅ | ✅ | ✅ Skip | N/A (LazyVim defaults) |
| Swap files | ✅ | ❌ | ✅ Added | High |
| Auto-reload | ✅ | ❌ | ✅ Added | High |
| Prettier | ❌ | ❌ | ✅ Added | High |

---

## Next Steps

1. ✅ Basic setup complete
2. ✅ Disabled swap files (2024-11-17)
3. ✅ Disabled netrw (2024-11-17)
4. ✅ Added auto-reload files (2024-11-17)
5. ✅ Configured prettier for markdown (2024-11-17)
6. ✅ Using LazyVim default keymaps (no custom keymaps needed)
7. ✅ Removed no-neck-pain.nvim, using built-in Snacks.zen (2025-12-04)
8. ✅ Disabled nvim-cmp integration in obsidian.nvim (2025-12-04)
9. ✅ Added custom todo checkbox toggle `<leader>td` (2025-12-04)
10. ✅ Clean up old config backups (2025-12-04)
11. ✅ Created todo.lua plugin - moved keymaps from keymaps.lua (2025-12-12)
12. ✅ Created daily-notes.lua plugin - `<leader>nt`, `<leader>ny` (2025-12-12)
13. ✅ Removed obsidian.nvim, centralized env vars in init.lua (2026-04-25)
16. ✅ Enhanced `gf` with markdown #heading support (2026-02-14)
17. ✅ Changed colorscheme to `catppuccin-mocha` — nvim 0.12 ships builtin `catppuccin.vim` (static colors, no config support) which conflicts with plugin name; using flavour-specific name avoids collision and keeps transparent_background/styles/integrations working (2026-03-31)
14. ✅ Enabled render-markdown.nvim — `render_modes = true`, custom checkbox states for `[>]`/`[~]`/`[!]`, smaller bullet glyphs. Note: LazyVim's `extras.lang.markdown` disables checkboxes by default, so we override `checkbox.enabled = true` (2026-05-12)
15. ✅ Added vim-tmux-navigator (2025-12-20)

---

## Notes

- Old config backed up at `~/.config/nvim.bak-current`
- Git tracked at `~/dotfiles/nvim/`
- LazyVim docs: https://www.lazyvim.org
- Use `:LazyExtras` to browse available extras
