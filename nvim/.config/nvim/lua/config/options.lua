-- Custom options to override LazyVim defaults

-- Disable netrw (using neo-tree instead)
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

local opt = vim.opt

-- Disable mouse
opt.mouse = ""

-- Don't use swap files
opt.swapfile = false

-- Keep cursor centered with context lines
opt.scrolloff = 5

-- Visual column guide at 80 characters
opt.colorcolumn = "80"

-- No line wrapping
opt.wrap = false

-- 2-space indentation (prettier default)
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Disable snacks animations
vim.g.snacks_animate = false

-- Auto-reload files when modified externally
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = "*",
  group = vim.api.nvim_create_augroup("auto-read", { clear = true }),
})
