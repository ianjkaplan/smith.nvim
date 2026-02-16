---@class SmithProviders
local M = {}

---@class SmithProviderCommandSpec
---@field cmd string
---@field args string[]

-- Setup prompt to get the agent to edit quickly.
local prompt = [[
Based on the following text make the relavent code
reason through changes as needed but DO NOT summarize
the changes. Once all the requested changes are made
stop immediately.
]]

---Build the final prompt text with optional context.
---@param text string
---@param context? SmithContext
---@return string
function M.build_text(text, context)
  local full_text = prompt .. text

  if context then
    full_text = string.format(
      "%s\n\nContext from %s (lines %d-%d):\n```\n%s\n```",
      full_text,
      context.location,
      context.start,
      context.finish,
      context.content
    )
  end

  return full_text
end

---Get the active provider and internal command spec.
---@param config ValidatedSmithConfig
---@return SmithProviderName
---@return SmithProviderCommandSpec
function M.get_active(config)
  ---@type table<SmithProviderName, SmithProviderCommandSpec>
  local provider_commands = {
    codex = {
      cmd = "codex",
      args = { "exec", "--json", "--full-auto" },
    },
    agent = {
      cmd = "agent",
      args = { "-p", "--output-format=stream-json" },
    },
  }

  ---@type SmithProviderName
  local provider = config.provider
  ---@type SmithProviderCommandSpec
  local provider_cfg = provider_commands[provider]
  return provider, provider_cfg
end

---Build provider command for a job.
---@param config ValidatedSmithConfig
---@param opts SmithJobOpts
---@return SmithProviderName
---@return string[]
function M.build_cmd(config, opts)
  local provider, provider_cfg = M.get_active(config)

  local text = M.build_text(opts.text, opts.context)
  local cmd = { provider_cfg.cmd }
  vim.list_extend(cmd, provider_cfg.args)
  table.insert(cmd, text)

  return provider, cmd
end

return M
