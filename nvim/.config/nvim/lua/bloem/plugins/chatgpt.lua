return {
  -- Let chatgpt help me with notes and stuff
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  config = function()
    require("chatgpt").setup({
      -- Get API key from macOS keychain
      api_key_cmd = "security find-generic-password -w -s OpenAI-API-key -a OpenAI-API-key",
    })
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "folke/trouble.nvim",
    "nvim-telescope/telescope.nvim",
  },
}
