---@class SmithConfig
---@field enabled boolean? Enable the plugin
---@field notify boolean? Show notifications
---@field autocmds boolean? Enable autocommands
---@field debug boolean? Enable debug mode
local M = {}

---@type SmithConfig
M.defaults = {
  enabled = true,
  notify = true,
  autocmds = false,
  debug = false,
}

---Validate configuration
---@param config SmithConfig
---@return boolean
---@return string?
function M.validate(config)
  vim.validate({
    enabled = { config.enabled, "boolean" },
    notify = { config.notify, "boolean" },
    autocmds = { config.autocmds, "boolean" },
    debug = { config.debug, "boolean" },
  })
  return true
end

return M
