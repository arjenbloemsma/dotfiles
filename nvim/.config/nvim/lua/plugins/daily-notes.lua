-- Daily notes navigation
--
-- Quick access to daily notes without obsidian.nvim dependency.
--
-- Keymaps:
--   <leader>nt - Open today's note
--   <leader>ny - Open yesterday's note
--
-- Creates note from template if it doesn't exist.
-- Vault path is read from $NOTES_VAULT env var (set in .zshrc).

local vault_path = vim.fn.expand(vim.g.NOTES_VAULT)
local dailies_path = vault_path .. "/dailies"
local template_path = vault_path .. "/templates/daily-note-template.md"

-- Open daily note for given date offset (0 = today, -1 = yesterday, 1 = tomorrow)
local open_daily = function(day_offset)
  local date = os.date("%Y-%m-%d", os.time() + (day_offset * 86400))
  local file_path = dailies_path .. "/" .. date .. ".md"

  -- Create from template if file doesn't exist
  if vim.fn.filereadable(file_path) == 0 then
    local template = vim.fn.readfile(template_path)
    vim.fn.writefile(template, file_path)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(file_path))
end

return {
  "folke/which-key.nvim",
  keys = {
    {
      "<leader>nt",
      function()
        open_daily(0)
      end,
      desc = "Open today's note",
    },
    {
      "<leader>ny",
      function()
        open_daily(-1)
      end,
      desc = "Open yesterday's note",
    },
  },
}
