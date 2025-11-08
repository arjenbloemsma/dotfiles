return {
  "shortcuts/no-neck-pain.nvim",
  -- stable version
  version = "*",
  keys = { { "<leader>nn", "<cmd>NoNeckPain<cr>", desc = "[N]o [N]eckpain" } },
  opts = {},
  config = function()
    require("no-neck-pain").setup({
      width = 114,
    })
  end,
}
