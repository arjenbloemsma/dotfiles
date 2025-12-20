-- Seamless navigation between tmux panes and nvim splits
-- Uses Ctrl+h/j/k/l to move between panes regardless of whether
-- you're in a tmux pane or nvim split

return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate previous" },
  },
}
