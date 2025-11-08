-- Disable netrw
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

local opt = vim.opt

-- Show linenumbers relative to the cursor
opt.relativenumber = true
opt.number = true

-- Disable mouse
opt.mouse = ""

-- Have a few lines abice and below the cursor
opt.scrolloff = 5

-- Show an indicator to keep our lines at a decent size
opt.colorcolumn = "80"

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false

-- Don't show the tabline
-- Note: in LazyVim distro we also need to disable
-- Bufferline.nvim plugin to completely remove the tabline
opt.showtabline = 0

-- Disable highlighting of the current line
opt.cursorline = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.cursorline = true

-- turn on termguicolors for tokyonight colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false

-- set filetype for .env.* files
vim.filetype.add({
  pattern = {
    ["%.env%..*"] = "sh",
  },
})

-- conceallevel of 1 or 2 is needed for Obsidian plugin
-- Level 1 "replaces" characters, level 2 also "cleans up" any whitespace
-- that is left behind after the replace action
vim.opt_local.conceallevel = 2

-- Highlight on yank
-- See `:help vim.highlight.on_yank()`
local highlight_group =
  vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- Autosave when moving (focus) away from the buffer
-- vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
--   callback = function()
--     local curbuf = vim.api.nvim_get_current_buf()
--     if
--       -- nvim_get_option_value
--       -- not vim.api.nvim_buf_get_option(curbuf, "modified")
--       not vim.api.nvim_get_option_value("modified", curbuf)
--       or vim.fn.getbufvar(curbuf, "&modifiable") == 0
--     then
--       return
--     end
--
--     vim.cmd([[silent! update]])
--   end,
--   pattern = "*",
--   group = vim.api.nvim_create_augroup("bloem-auto-save", { clear = true }),
-- })

-- Auto-reload files when modified externally
-- https://unix.stackexchange.com/a/383044
vim.o.autoread = true
vim.api.nvim_create_autocmd(
  { "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" },
  {
    command = "if mode() != 'c' | checktime | endif",
    pattern = { "*" },
    group = vim.api.nvim_create_augroup("bloem-auto-read", { clear = true }),
  }
)
