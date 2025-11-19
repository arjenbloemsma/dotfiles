-- Lazygit integration via snacks.nvim
-- Automatically configures lazygit colorscheme to match nvim theme
return {
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = {
        enabled = true,
        configure = true, -- Auto-configure lazygit to match nvim colorscheme
      },
    },
    keys = {
      { "<leader>lg", function() Snacks.lazygit() end, desc = "Lazygit" },
    },
  },
}
