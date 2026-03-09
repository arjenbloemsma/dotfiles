return {
  {
    "iamcco/markdown-preview.nvim",
    config = function()
      vim.g.mkdp_browserfunc = "OpenMarkdownPreview"
      vim.cmd([[
        function! OpenMarkdownPreview(url)
          execute 'silent !/Applications/Firefox.app/Contents/MacOS/firefox --profile "/Users/arjenbloemsma/Library/Application Support/Firefox/Profiles/F0KdqyUG.Profile 3" ' . shellescape(a:url) . ' &'
        endfunction
      ]])
      vim.cmd([[do FileType]])
    end,
  },
  {
    "folke/which-key.nvim",
    keys = {
      {
        "<leader>mp",
        function()
          local file = vim.fn.expand("%:p")
          vim.cmd("terminal glow -p " .. vim.fn.shellescape(file))
        end,
        desc = "Preview markdown with glow",
      },
    },
  },
}
