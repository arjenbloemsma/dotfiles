-- Custom options to override LazyVim defaults
local opt = vim.opt

-- Disable mouse
opt.mouse = ""

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
