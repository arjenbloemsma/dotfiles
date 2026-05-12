-- Disable unwanted LazyVim features and behaviors
--
-- This file consolidates all disabled plugins and features to keep config clean
-- and clearly document what we've turned off.

return {
  -- ============================================================================
  -- SNACKS.NVIM - Disable dashboard and explorer
  -- ============================================================================
  -- LazyVim's utility plugin - disable dashboard and file explorer
  -- Using mini.files instead for file browsing
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
      explorer = { enabled = false },
    },
    keys = {
      -- Unmap snacks explorer keybindings (replaced by mini.files)
      { "<leader>e", false },
      { "<leader>E", false },
    },
  },

  -- ============================================================================
  -- BUFFERLINE (Tab bar at top)
  -- ============================================================================
  -- Shows open buffers as tabs at the top of the window
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },

  -- ============================================================================
  -- MINI.PAIRS - Auto-pairing of quotes, brackets, braces
  -- ============================================================================
  -- Automatically creates closing pairs for quotes, brackets, braces
  -- Disabled as it interferes with Vi typing workflow
  {
    "nvim-mini/mini.pairs",
    enabled = false,
  },
}
