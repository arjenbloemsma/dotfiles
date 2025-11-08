return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>on", "<cmd>ObsidianNew<CR>", desc = "Obsidian New Note (Zettelkasten)" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", desc = "Obsidian Quick Switch" },
    { "<leader>oo", "<cmd>ObsidianSearch<CR>", desc = "Obsidian Search" },
    { "<leader>oy", "<cmd>ObsidianYesterday<CR>", desc = "Obsidian Yesterday" },
    { "<leader>ot", "<cmd>ObsidianToday<CR>", desc = "Obsidian Today" },
    { "<leader>otm", "<cmd>ObsidianTomorrow<CR>", desc = "Obsidian Tomorrow" },
    { "<leader>ods", "<cmd>ObsidianDailies 3<CR>", desc = "Obsidian Dailies" },
    { "<leader>oe", "<cmd>ObsidianExtractNote<CR>", desc = "Obsidian Extract Note" },
  },
  opts = {
    workspaces = {
      {
        name = "notes",
        path = "~/Documents/notes-vault",
      },
    },
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },
    new_notes_location = "current_dir",
    daily_notes = {
      folder = "dailies",
      template = "~/Documents/notes-vault/templates/daily-note-template.md",
    },
    wiki_link_func = function(opts)
      if opts.id == nil then
        return string.format("[[%s]]", opts.label)
      elseif opts.label ~= opts.id then
        return string.format("[[%s|%s]]", opts.id, opts.label)
      else
        return string.format("[[%s]]", opts.id)
      end
    end,
    mappings = {
      ["<leader>of"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      ["<leader>od"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
    },
    note_frontmatter_func = function(note)
      local out = { id = note.id, aliases = note.aliases, tags = note.tags, project = "" }
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end
      return out
    end,
    note_id_func = function(title)
      -- Zettelkasten style: timestamp-based IDs for unique, sortable filenames
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,
    templates = {
      subdir = "Templates",
      date_format = "%Y-%m-%d-%a",
      time_format = "%H:%M",
      tags = "",
    },
  },
}
