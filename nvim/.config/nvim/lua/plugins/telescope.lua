-- Telescope file finder configuration
-- Show hidden files (dotfiles) and gitignored files
return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        -- Only ignore .git directory itself
        file_ignore_patterns = { "^.git/" },
      },
      pickers = {
        find_files = {
          hidden = true,    -- Show dotfiles (files starting with .)
          no_ignore = true, -- Show gitignored files
        },
      },
    },
  },
}
