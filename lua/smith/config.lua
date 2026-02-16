---@class SmithConfig
---@field enabled boolean? Enable the plugin
---@field keymaps boolean? Enable default keymaps
---@field keymap_prefix string? Prefix for keymaps (default: "<leader>m")
---@field provider SmithProviderName? Active provider (default: "codex")
---
---@class ValidatedSmithConfig
---@field enabled boolean
---@field keymaps boolean
---@field keymap_prefix string
---@field provider SmithProviderName
---
---@alias SmithProviderName "codex"|"agent"|"claude"
local M = {}

---@type ValidatedSmithConfig
M.defaults = {
  enabled = true,
  keymaps = true,
  keymap_prefix = "<leader>m",
  provider = "codex",
}

---Validate configuration
---@param config SmithConfig
---@return ValidatedSmithConfig
function M.validate(config)
  local providers = { "codex", "agent", "claude" }

  vim.validate({
    enabled = { config.enabled, "boolean" },
    keymaps = { config.keymaps, "boolean" },
    keymap_prefix = { config.keymap_prefix, "string" },
    provider = {
      config.provider,
      function(value)
        return type(value) == "string" and vim.tbl_contains(providers, value)
      end,
      "one of: codex, agent, claude",
    },
  })

  ---@cast config ValidatedSmithConfig
  return config
end

return M
