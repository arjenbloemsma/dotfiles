return {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      -- LSPs
      "bash-language-server", -- bash/shell LSP
      "bicep-lsp", -- Azure Bicep LSP
      "docker-compose-language-service", -- docker-compose.yml LSP
      "dockerfile-language-server", -- Dockerfile LSP
      "json-lsp", -- JSON LSP
      "lua-language-server", -- Lua LSP (nvim config)
      "marksman", -- markdown LSP (navigation, references)
      "svelte-language-server", -- Svelte component LSP
      "tailwindcss-language-server", -- Tailwind CSS class completion
      "vtsls", -- TypeScript LSP (LazyVim default)

      -- Linters
      "hadolint", -- Dockerfile linter
      "markdownlint-cli2", -- markdown style linter
      "shellcheck", -- shell script linter (used by bashls)

      -- Formatters
      "prettier", -- markdown formatter (only format biome can't do)
      "shfmt", -- shell script formatter
      "stylua", -- Lua formatter
    },
  },
}
