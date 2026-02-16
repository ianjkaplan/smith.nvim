---@class SmithCodexParser
local M = {}

---@class SmithCodexParseResult
---@field lines string[]
---@field replace_thinking boolean
---@field is_streaming boolean
---@field type string|nil

---@class SmithCodexParserState
---@field thread_id string|nil
---@field is_streaming boolean
local default_state = {
  thread_id = nil,
  is_streaming = false,
}

---@type SmithCodexParserState
M.state = vim.deepcopy(default_state)

function M.reset()
  M.state = vim.deepcopy(default_state)
end

---@param line string
---@return table|nil
local function parse_json(line)
  if not line or line == "" then
    return nil
  end

  local ok, result = pcall(vim.json.decode, line)
  if ok then
    return result
  end

  return nil
end

---@param data table
---@return string[]
local function format_thread_started(data)
  local lines = { "── System ──" }
  if data.thread_id then
    M.state.thread_id = data.thread_id
    table.insert(lines, "Thread: " .. string.sub(data.thread_id, 1, 8) .. "...")
  end
  table.insert(lines, "")
  return lines
end

---@alias CodexItemHandler fun(item: table): string[]

---@type table<string, CodexItemHandler>
local item_handlers

---@param item table
---@return string[]
local function format_item_completed(item)
  local handler = item_handlers[item.type]
  if not handler then
    return {}
  end
  return handler(item)
end

---@param data table
---@return string[]
local function format_turn_completed(data)
  local lines = {
    "── Result ──",
    "✓ Status: Success",
  }

  if data.usage then
    local usage = data.usage
    if usage.input_tokens then
      table.insert(lines, "Input Tokens: " .. usage.input_tokens)
    end
    if usage.cached_input_tokens then
      table.insert(lines, "Cached Input Tokens: " .. usage.cached_input_tokens)
    end
    if usage.output_tokens then
      table.insert(lines, "Output Tokens: " .. usage.output_tokens)
    end
  end

  table.insert(lines, "")
  return lines
end

item_handlers = {
  reasoning = function(item)
    if not item.text then
      return {}
    end
    local lines = { "── Thinking ──" }
    vim.list_extend(lines, vim.split(item.text, "\n"))
    table.insert(lines, "")
    return lines
  end,

  agent_message = function(item)
    if not item.text then
      return {}
    end
    local lines = { "── Assistant ──" }
    vim.list_extend(lines, vim.split(item.text, "\n"))
    table.insert(lines, "")
    return lines
  end,
}

---@alias CodexTypeHandler fun(data: table, result: SmithCodexParseResult): nil

---@type table<string, CodexTypeHandler>
local type_handlers = {
  ["thread.started"] = function(data, result)
    result.lines = format_thread_started(data)
  end,

  ["item.completed"] = function(data, result)
    if data.item then
      result.lines = format_item_completed(data.item)
    end
  end,

  ["turn.completed"] = function(data, result)
    result.lines = format_turn_completed(data)
  end,
}

---@param line string
---@return SmithCodexParseResult
function M.parse_line(line)
  local result = {
    lines = {},
    replace_thinking = false,
    is_streaming = false,
    type = nil,
  }

  local data = parse_json(line)
  if not data then
    return result
  end

  result.type = data.type

  local handler = type_handlers[data.type]
  if handler then
    handler(data, result)
  end

  return result
end

---@class SmithCodexStreamState
---@field lines string[]

---@return SmithCodexStreamState
function M.create_stream_state()
  return { lines = {} }
end

---@param stream_state SmithCodexStreamState
---@param line string
---@return SmithCodexStreamState, boolean
function M.parse_and_update(stream_state, line)
  local result = M.parse_line(line)
  if #result.lines == 0 then
    return stream_state, false
  end

  vim.list_extend(stream_state.lines, result.lines)
  return stream_state, true
end

---@param raw_lines string[]
---@return string[]
function M.parse_stream(raw_lines)
  M.reset()
  local stream_state = M.create_stream_state()
  for _, line in ipairs(raw_lines) do
    stream_state = M.parse_and_update(stream_state, line)
  end
  return stream_state.lines
end

---@return boolean
function M.is_streaming()
  return M.state.is_streaming
end

---@return table
function M.get_session_info()
  return {
    session_id = M.state.thread_id,
    model = nil,
  }
end

return M
