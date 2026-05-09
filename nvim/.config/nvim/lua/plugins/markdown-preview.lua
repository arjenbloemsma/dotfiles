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
}
