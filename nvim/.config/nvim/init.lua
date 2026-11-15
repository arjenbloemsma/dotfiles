-- A devpod container holds no notes vault, so the vault plugins and the check
-- below are skipped there. podman writes /run/.containerenv.
vim.g.in_container = vim.uv.fs_stat("/run/.containerenv") ~= nil

-- Dev containers ship no ICU library; marksman (.NET) aborts at startup
-- without it unless told to run without locale data.
if vim.g.in_container then
  vim.env.DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1"
end

-- Load and validate required environment variables
if not vim.g.in_container then
  local required_env = { "NOTES_VAULT" }
  for _, var in ipairs(required_env) do
    local val = os.getenv(var)
    if not val then
      vim.api.nvim_err_writeln(var .. " env var is not set")
    end
    vim.g[var] = val
  end
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
