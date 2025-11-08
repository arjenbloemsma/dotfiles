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

### 2. No Neck Pain (`no-neck-pain.lua`)
**Why**: Ergonomic centered coding view, reduces eye strain
**Keymap**: `<leader>uz` - Toggle zen mode
**Config**: 120 character width
**Status**: ✅ Working

**Note**: Originally `<leader>nn` conflicted with LazyVim's `<leader>n` (notifications)

---

### 3. Obsidian.nvim (`obsidian.lua`)
**Why**: Note-taking integration with Obsidian vault
**Vault**: `~/Documents/notes-vault`
**Features**:
- Zettelkasten-style note IDs (timestamp-based)
- Daily notes with templates
- Wiki links and frontmatter management
- Checkbox toggling

**Keymaps**:
- `<leader>on` - New note (Zettelkasten)
- `<leader>oq` - Quick switch notes
- `<leader>oo` - Search notes
- `<leader>ot` - Today's daily
- `<leader>oy` - Yesterday's daily
- `<leader>otm` - Tomorrow's daily
- `<leader>ods` - Dailies picker (last 7 days)
- `<leader>oe` - Extract note
- `<leader>of` - Follow link (buffer mapping)
- `<leader>od` - Toggle checkbox (buffer mapping)

**Dependencies**: Uses fzf-lua for pickers (LazyVim default)
**Status**: ⚠️ Some issues reported (to be investigated)

---

### 4. LazyGit (`lazygit.lua`)
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

### 5. Harpoon
**Why**: Quick file navigation (Prime's workflow)
**How added**: Via LazyVim extras menu
**Status**: ✅ Installed

---

## Custom Options (`lua/config/options.lua`)

Settings that override LazyVim defaults:

```lua
opt.mouse = ""           -- Disable mouse (keyboard-only workflow)
opt.scrolloff = 5        -- Keep 5 lines context above/below cursor
opt.colorcolumn = "80"   -- Visual guide at column 80
opt.wrap = false         -- No line wrapping
opt.showtabline = 0      -- Hide tabline completely
opt.tabstop = 2          -- 2-space indentation
opt.shiftwidth = 2       -- 2-space indentation
opt.expandtab = true     -- Expand tabs to spaces
opt.autoindent = true    -- Copy indent from current line
```

**Why**: Personal coding preferences, consistency with prettier defaults

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
   - Status: 🔲 Not yet added
   - Decision needed: Critical for tmux workflow?

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
├── init.lua                    # LazyVim entry point
├── lua/
│   ├── config/
│   │   └── options.lua         # ✨ Custom options override
│   └── plugins/
│       ├── colorscheme.lua     # ✨ Catppuccin config
│       ├── no-neck-pain.lua    # ✨ Zen mode
│       ├── obsidian.lua        # ✨ Note-taking
│       ├── lazygit.lua         # ✨ Git UI
│       └── example.lua         # LazyVim examples
├── CUSTOMIZATIONS.md           # This file
└── [LazyVim default files...]
```

**✨** = Custom additions

---

## Decision Matrix

Use this to evaluate future customizations:

| Feature | Old Config | LazyVim | Action | Priority |
|---------|-----------|---------|--------|----------|
| Catppuccin theme | ✅ | ❌ | ✅ Added | High |
| No neck pain | ✅ | ❌ | ✅ Added | Medium |
| Obsidian | ✅ | ❌ | ✅ Added | High |
| LazyGit | ✅ | ❌ | ✅ Added | High |
| Harpoon | ✅ | Extra | ✅ Added | High |
| ChatGPT | ✅ | ❌ | 🔲 Pending | Low |
| Tmux nav | ✅ | ❌ | 🔲 Pending | High |
| Telescope | ✅ | fzf-lua | ✅ Skip | N/A |
| jk->ESC | ✅ | ❌ | 🔲 Pending | Medium |
| Auto-save | ✅ | ❌ | 🔲 Pending | Low |

---

## Next Steps

1. ✅ Basic setup complete
2. ⏳ Evaluate Obsidian issues
3. 🔲 Decide on missing keymaps
4. 🔲 Add vim-tmux-navigator if needed
5. 🔲 Test workflow for a week
6. 🔲 Add ChatGPT if still needed
7. 🔲 Clean up old config backups

---

## Notes

- Old config backed up at `~/.config/nvim.bak-current`
- Git tracked at `~/dotfiles/nvim/`
- LazyVim docs: https://www.lazyvim.org
- Use `:LazyExtras` to browse available extras
