-- Simplified lualine config - cleaner statusline for tmux workflow
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    -- Remove current directory from section c (redundant with tmux)
    opts.sections = opts.sections or {}

    -- Keep: mode, git, diagnostics, filename
    -- Remove: directory, progress, some metadata
    opts.sections.lualine_c = {
      {
        "diagnostics",
      },
      {
        "filename",
        path = 1, -- Relative path
      },
    }

    -- Simplified right side: filetype, location, encoding
    opts.sections.lualine_x = {
      {
        "filetype",
        icon_only = false,
      },
    }

    opts.sections.lualine_y = {
      { "location" },
    }

    opts.sections.lualine_z = {
      { "encoding" },
    }

    -- Clean up inactive sections too
    opts.inactive_sections = opts.inactive_sections or {}
    opts.inactive_sections.lualine_c = {
      {
        "filename",
        path = 1,
      },
    }

    return opts
  end,
}
