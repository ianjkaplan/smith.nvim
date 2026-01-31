---@class Smith
---@field config SmithConfig
local M = {}

---@type SmithConfig
M.config = require("smith.config").defaults

---Main setup funciton for smith.nvim with user configuration
---@param opts? SmithConfig
function M.setup(opts)
  vim.notify("Hello", vim.log.levels.WARN)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Set up user commands
  M._setup_commands()

  -- Set up autocommands if enabled
  if M.config.autocmds then
    M._setup_autocmds()
  end
end

---Set up user commands
function M._setup_commands()
  vim.api.nvim_create_user_command("Smith", function(args)
    M.run(args.args)
  end, {
    nargs = "?",
    desc = "Run smith.nvim",
  })
end

---Set up autocommands
function M._setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("Smith", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function()
      -- Add your autocmd logic here
    end,
  })
end

---Main plugin functionality
---@param input string
---@return string
function M.run(input)
  if M.config.notify then
    vim.notify(input, vim.log.levels.WARN)
  end
  return input
end

---Get the current configuration
---@return SmithConfig
function M.get_config()
  return M.config
end

return M
