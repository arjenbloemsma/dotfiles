-- Load and validate required environment variables
local required_env = { "NOTES_VAULT" }
for _, var in ipairs(required_env) do
  local val = os.getenv(var)
  if not val then
    vim.api.nvim_err_writeln(var .. " env var is not set")
  end
  vim.g[var] = val
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
