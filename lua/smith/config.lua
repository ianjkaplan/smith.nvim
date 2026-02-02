---@class SmithConfig
---@field enabled boolean? Enable the plugin
---@field keymaps boolean? Enable default keymaps
---@field keymap_prefix string? Prefix for keymaps (default: "<leader>m")
local M = {}

---@type SmithConfig
M.defaults = {
  enabled = true,
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
    keymaps = { config.keymaps, "boolean" },
    keymap_prefix = { config.keymap_prefix, "string" },
  })
  return true
end

return M
