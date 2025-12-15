-- Todo checkbox management for markdown files
--
-- Keymaps:
--   <leader>td - Toggle checkbox ([ ] <-> [x])
--   <leader>tc - Convert line(s) to todo items
--
-- Works in normal and visual mode for single/multi-line operations.

-- Toggle checkbox on a single line
local toggle_checkbox_line = function(line)
  if line:match("%- %[ %]") then
    return line:gsub("%- %[ %]", "- [x]", 1)
  elseif line:match("%- %[x%]") then
    return line:gsub("%- %[x%]", "- [ ]", 1)
  end
  return nil
end

local toggle_checkbox = function()
  local line = vim.api.nvim_get_current_line()
  local new_line = toggle_checkbox_line(line)
  if new_line then
    vim.api.nvim_set_current_line(new_line)
  end
end

local toggle_checkbox_range = function(start_line, end_line)
  for lnum = start_line, end_line do
    local line = vim.fn.getline(lnum)
    local new_line = toggle_checkbox_line(line)
    if new_line then
      vim.fn.setline(lnum, new_line)
    end
  end
end

-- Convert text line(s) to todo items
-- "- item" -> "- [ ] item"
-- "* item" -> "- [ ] * item"
-- "1. item" -> "- [ ] 1. item"
-- "plain text" -> "- [ ] plain text"
local make_todo_line = function(line)
  -- Skip if already a checkbox
  if line:match("^%s*%- %[.%]") then
    return line
  end
  local indent = line:match("^(%s*)") or ""
  local rest = line:gsub("^%s*", "")
  -- Skip empty lines
  if rest == "" then
    return line
  end
  -- "- item" -> "- [ ] item" (replace dash list marker)
  if rest:match("^%- ") then
    return indent .. "- [ ] " .. rest:sub(3)
  end
  -- Everything else: prepend "- [ ] "
  return indent .. "- [ ] " .. rest
end

local make_todo = function()
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(make_todo_line(line))
end

local make_todo_range = function(start_line, end_line)
  for lnum = start_line, end_line do
    local line = vim.fn.getline(lnum)
    vim.fn.setline(lnum, make_todo_line(line))
  end
end

return {
  "folke/which-key.nvim",
  keys = {
    { "<leader>td", toggle_checkbox, desc = "Toggle todo checkbox" },
    {
      "<leader>td",
      function()
        local start_line = vim.fn.line("v")
        local end_line = vim.fn.line(".")
        if start_line > end_line then
          start_line, end_line = end_line, start_line
        end
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        toggle_checkbox_range(start_line, end_line)
      end,
      mode = "v",
      desc = "Toggle todo checkboxes",
    },
    { "<leader>tc", make_todo, desc = "Convert to todo" },
    {
      "<leader>tc",
      function()
        local start_line = vim.fn.line("v")
        local end_line = vim.fn.line(".")
        if start_line > end_line then
          start_line, end_line = end_line, start_line
        end
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        make_todo_range(start_line, end_line)
      end,
      mode = "v",
      desc = "Convert lines to todos",
    },
  },
}
