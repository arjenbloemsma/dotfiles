return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      "prettier", -- used by conform for markdown (lang.markdown configures but doesn't install)
      "bicep-lsp", -- Azure Bicep LSP
    },
  },
}
