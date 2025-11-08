-- LSP and UI configuration - Add borders to floating windows
return {
  -- Configure noice.nvim to show borders on LSP hover/signature help
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true, -- Add border to hover docs and signature help
      },
    },
  },
}
