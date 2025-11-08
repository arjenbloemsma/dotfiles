return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
  --   "BufReadPre path/to/my-vault/**.md",
  --   "BufNewFile path/to/my-vault/**.md",
  -- },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- config = function()
  --   -- conceallevel of 1 or 2 is needed for Obsidian plugin
  --   vim.opt_local.conceallevel = 2
  -- end,
  keys = {
    { "<leader>oo", "<cmd>ObsidianSearch<CR>", desc = "Obsidian Follow Link" },
    {
      "<leader>oy",
      "<cmd>ObsidianYesterday<CR>",
      desc = "Obsidian Open/create yesterdays daily",
    },
    {
      "<leader>ot",
      "<cmd>ObsidianToday<CR>",
      desc = "Obsidian Open/create todays daily",
    },
    {
      "<leader>otm",
      "<cmd>ObsidianTomorrow<CR>",
      desc = "Obsidian Open/create tomorrows daily",
    },
    {
      "<leader>ods",
      "<cmd>ObsidianDailies 3<CR>",
      desc = "Obsidian Open dailies in a picker list",
    },
    {
      "<leader>oe",
      "<cmd>ObsidianExtractNote<CR>",
      desc = "Obsidian Extract Note",
    },
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
      -- We want to keep daily notes in a separate directory.
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
      -- Obsidian follow
      ["<leader>of"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle check-boxes "obsidian done", create checkbox if not exists
      ["<leader>od"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- -- Create a new newsletter issue
      -- ["<leader>onn"] = {
      --   action = function()
      --     return require("obsidian").commands.new_note("Newsletter-Issue")
      --   end,
      --   opts = { buffer = true },
      -- },
      -- ["<leader>ont"] = {
      --   action = function()
      --     return require("obsidian").util.insert_template("Newsletter-Issue")
      --   end,
      --   opts = { buffer = true },
      -- },
    },
    note_frontmatter_func = function(note)
      -- This is equivalent to the default frontmatter function.
      local out =
        { id = note.id, aliases = note.aliases, tags = note.tags, project = "" }
      -- `note.metadata` contains any manually added fields in the frontmatter.
      -- So here we just make sure those fields are kept in the frontmatter.
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end
      return out
    end,
    note_id_func = function(title)
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
      local suffix = ""
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
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
