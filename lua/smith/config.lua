---@class SmithConfig
---@field enabled boolean? Enable the plugin
---@field notify boolean? Show notifications
---@field autocmds boolean? Enable autocommands
---@field debug boolean? Enable debug mode
---@field keymaps boolean? Enable default keymaps
---@field keymap_prefix string? Prefix for keymaps (default: "<leader>m")
local M = {}

---@type SmithConfig
M.defaults = {
  enabled = true,
  notify = true,
  autocmds = false,
  debug = false,
  keymaps = true,
  keymap_prefix = "<leader>m",
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
    keymaps = { config.keymaps, "boolean" },
    keymap_prefix = { config.keymap_prefix, "string" },
  })
  return true
end

return M
