-- Noice.nvim configuration - UI improvements
return {
  -- Add borders to LSP hover/signature help and configure cmdline
  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        view = "cmdline", -- Use traditional bottom cmdline instead of popup
      },
      presets = {
        bottom_search = true,    -- Use classic bottom cmdline for search
        command_palette = false, -- Disable fancy popup command palette
        lsp_doc_border = true,   -- Add border to hover docs and signature help
      },
    },
  },
}
