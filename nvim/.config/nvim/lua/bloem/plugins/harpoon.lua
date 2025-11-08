return {
  -- Harpoon for quick file navigation
  "theprimeagen/harpoon",
  branch = "harpoon2",
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
    keys = {},
  },

  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    vim.keymap.set("n", "<C-a>", function()
      harpoon:list():add()
    end, { desc = "Add current file to Harpoon" })
    vim.keymap.set("n", "<C-q>", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Toggle Harpoon menu" })

    vim.keymap.set("n", "<C-n>", function()
      harpoon:list():select(1)
    end, { desc = "Harpoon to location 1" })
    vim.keymap.set("n", "<C-e>", function()
      harpoon:list():select(2)
    end, { desc = "Harpoon to location 2" })
    -- vim.keymap.set("n", "<C-e>", function()
    --   harpoon:list():select(3)
    -- end, { desc = "Harpoon to location 3" })
    -- INFO: We keep using the default <C-O> (back) and <C-I> (forward)
    -- for going back and forward in the buffer history, so files and
    -- even locations in files we've visited

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<C-S-P>", function()
      harpoon:list():prev()
    end, { desc = "Toggle previous buffer in Harpoon list" })
    vim.keymap.set("n", "<C-S-N>", function()
      harpoon:list():next()
    end, { desc = "Toggle previous buffer in Harpoon list" })
  end,
}
