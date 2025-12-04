-- Custom keymaps to override LazyVim defaults

-- Toggle markdown todo checkbox (- [ ] <-> - [x])
local toggle_checkbox = function()
  local line = vim.api.nvim_get_current_line()
  local new_line

  if line:match("%- %[ %]") then
    new_line = line:gsub("%- %[ %]", "- [x]", 1)
  elseif line:match("%- %[x%]") then
    new_line = line:gsub("%- %[x%]", "- [ ]", 1)
  else
    return
  end

  vim.api.nvim_set_current_line(new_line)
end

vim.keymap.set("n", "<leader>td", toggle_checkbox, { desc = "Toggle todo checkbox" })
