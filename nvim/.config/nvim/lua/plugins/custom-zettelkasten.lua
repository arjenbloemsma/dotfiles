-- Custom zettelkasten functionality
--
-- Tag search: Standard zettelkasten plugins (telekasten.nvim) don't properly
-- parse YAML list format tags. This provides custom telescope-based tag search
-- that works with frontmatter like:
--
--   tags:
--     - tag-one
--     - tag-two
--
-- Enhanced gf: native gf treats #anchor as part of the filename (# is in
-- isfname). This override strips the anchor, opens the file, then jumps to
-- the matching markdown heading.
--
-- Commands:
--   :NotesTags  - Interactive tag browser (pick tag, then see matching notes)
--   :NotesTag <name> - Search for specific tag directly
--
-- Keymaps:
--   <leader>zt - Open interactive tag browser
--   gf         - Go to file with markdown #heading support

return {
  -- Extend telescope with custom zettelkasten commands
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>zt", "<cmd>NotesTags<CR>", desc = "Zettelkasten tag search" },
  },
  config = function()
    local vault_path = vim.fn.expand(vim.g.NOTES_VAULT)

    -- Direct tag search: find all notes containing a specific tag
    -- Usage: :NotesTag governance
    vim.api.nvim_create_user_command("NotesTag", function(opts)
      local tag = opts.args
      require("telescope.builtin").grep_string({
        -- Match YAML list item format (two spaces, dash, space, tagname)
        search = "  - " .. tag,
        cwd = vault_path,
        glob_pattern = "*.md",
        prompt_title = "Tag: " .. tag,
        -- Root-only: zettelkasten notes live at vault root, subfolders
        -- (dailies/, templates/, etc.) don't contain tagged notes
        additional_args = { "--max-depth", "1" },
      })
    end, { nargs = 1, desc = "Search notes by tag" })

    -- Interactive tag browser: shows all tags with counts, then searches on selection
    -- Usage: :NotesTags or <leader>zt
    vim.api.nvim_create_user_command("NotesTags", function()
      -- Use ripgrep to find all unique tags in vault
      -- Pattern matches YAML list format: `  - tagname` (lowercase, numbers, hyphens)
      -- Output: sorted by frequency (most used tags first)
      -- Root-only: zettelkasten notes live at vault root, subfolders
      -- (dailies/, templates/, etc.) don't contain tagged notes
      local cmd = "rg -o '  - [a-z0-9-]+' --no-filename --max-depth 1 "
        .. vim.fn.shellescape(vault_path)
        .. " | sort | uniq -c | sort -rn"
      local results = vim.fn.systemlist(cmd)

      -- Parse ripgrep output into structured tag list
      -- Input format: "  42   - tagname" (count + match)
      local tags = {}
      for _, line in ipairs(results) do
        local count, tag = line:match("^%s*(%d+)%s+  %- (.+)$")
        if tag then
          table.insert(tags, { tag = tag, count = tonumber(count) })
        end
      end

      -- Build telescope picker with tag list
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      pickers.new({}, {
        prompt_title = "Select Tag",
        finder = finders.new_table({
          results = tags,
          -- Format each entry as "tagname        (count)"
          entry_maker = function(entry)
            return {
              value = entry.tag,
              display = string.format("%-30s (%d)", entry.tag, entry.count),
              ordinal = entry.tag,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        -- On selection: close picker and search for that tag
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection then
              vim.cmd("NotesTag " .. selection.value)
            end
          end)
          return true
        end,
      }):find()
    end, { desc = "Browse and search notes by tag" })

    -- Enhanced gf: # is in isfname by default, so native gf includes it in the
    -- filename (e.g. file.md#heading). We temporarily remove # from isfname,
    -- let native gf resolve the file, then jump to the heading.
    vim.keymap.set("n", "gf", function()
      local cfile = vim.fn.expand("<cfile>")
      local anchor = cfile:match("#(.+)$")

      local saved = vim.o.isfname
      vim.opt.isfname:remove("#")

      local ok = pcall(function()
        vim.cmd("normal! gf")
      end)

      vim.o.isfname = saved

      if ok and anchor then
        local pattern = anchor:gsub("-", "[ -]")
        vim.fn.search("^#\\+\\s\\+.*" .. pattern, "w")
      end
    end, { desc = "Go to file (with markdown heading support)" })
  end,
}
