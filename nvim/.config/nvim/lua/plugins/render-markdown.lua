-- Render markdown inline (headings, lists, code blocks, etc.)
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    render_modes = true,
    bullet = {
      icons = { "•", "◦", "▪", "▫" },
    },
    checkbox = {
      enabled = true,
      custom = {
        ongoing = { raw = "[>]", rendered = "󰐊 ", highlight = "DiagnosticInfo" },
        attention = { raw = "[~]", rendered = "󰈸 ", highlight = "DiagnosticWarn" },
        blocked = { raw = "[!]", rendered = "󱒼 ", highlight = "DiagnosticError" },
      },
    },
  },
}
