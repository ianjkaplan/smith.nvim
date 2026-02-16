---@class SmithParser
local M = {}

local parsers = {
  agent = require("smith.parsers.agent"),
  codex = require("smith.parsers.codex"),
}

---@alias SmithParseResult SmithAgentParseResult|SmithCodexParseResult
---@alias SmithStreamState SmithAgentStreamState|SmithCodexStreamState

---@param provider SmithProviderName|nil
---@return table
local function get_parser(provider)
  return parsers[provider or "agent"] or parsers.agent
end

---@param provider SmithProviderName|nil
function M.reset(provider)
  get_parser(provider).reset()
end

---@param line string
---@param provider SmithProviderName|nil
---@return SmithParseResult
function M.parse_line(line, provider)
  return get_parser(provider).parse_line(line)
end

---@param provider SmithProviderName|nil
---@return SmithStreamState
function M.create_stream_state(provider)
  return get_parser(provider).create_stream_state()
end

---@param stream_state SmithStreamState
---@param line string
---@param provider SmithProviderName|nil
---@return SmithStreamState, boolean
function M.parse_and_update(stream_state, line, provider)
  return get_parser(provider).parse_and_update(stream_state, line)
end

---@param raw_lines string[]
---@param provider SmithProviderName|nil
---@return string[]
function M.parse_agent_stream(raw_lines, provider)
  return get_parser(provider).parse_stream(raw_lines)
end

---@param provider SmithProviderName|nil
---@return boolean
function M.is_streaming(provider)
  return get_parser(provider).is_streaming()
end

---@param provider SmithProviderName|nil
---@return table
function M.get_session_info(provider)
  return get_parser(provider).get_session_info()
end

return M
