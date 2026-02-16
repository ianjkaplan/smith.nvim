---@class SmithAgentParser
---@field state SmithAgentParserState
local M = {}

---@class SmithAgentParserState
---@field thinking_buffer string Accumulated thinking text
---@field session_id string|nil Current session ID
---@field model string|nil Model name
---@field is_streaming boolean Whether we're currently streaming
local default_state = {
  thinking_buffer = "",
  session_id = nil,
  model = nil,
  is_streaming = false,
}

---@type SmithAgentParserState
M.state = vim.deepcopy(default_state)

---Reset parser state for a new session.
function M.reset()
  M.state = vim.deepcopy(default_state)
end

---Parse a single JSON line.
---@param line string
---@return table|nil parsed JSON object or nil if invalid
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

---Format system initialization message.
---@param data table
---@return string[]
local function format_system(data)
  local lines = {}
  table.insert(lines, "── System ──")
  if data.model then
    table.insert(lines, "Model: " .. data.model)
    M.state.model = data.model
  end
  if data.session_id then
    table.insert(lines, "Session: " .. string.sub(data.session_id, 1, 8) .. "...")
    M.state.session_id = data.session_id
  end
  if data.cwd then
    table.insert(lines, "CWD: " .. data.cwd)
  end
  if data.permissionMode then
    table.insert(lines, "Permissions: " .. data.permissionMode)
  end
  table.insert(lines, "")
  return lines
end

---Format user message.
---@param data table
---@return string[]
local function format_user(data)
  local lines = {}
  table.insert(lines, "── User ──")

  local message = data.message
  if message and message.content then
    for _, content in ipairs(message.content) do
      if content.type == "text" and content.text then
        local text_lines = vim.split(content.text, "\n")
        for _, text_line in ipairs(text_lines) do
          table.insert(lines, text_line)
        end
      end
    end
  end

  table.insert(lines, "")
  return lines
end

---Format thinking delta (streaming).
---@param data table
---@return string[], boolean lines and whether to replace previous thinking block
local function format_thinking_delta(data)
  M.state.is_streaming = true
  M.state.thinking_buffer = M.state.thinking_buffer .. (data.text or "")

  local lines = {}
  table.insert(lines, "── Thinking... ──")

  local thought_lines = vim.split(M.state.thinking_buffer, "\n")
  for _, line in ipairs(thought_lines) do
    table.insert(lines, line)
  end

  return lines, true
end

---Format thinking completed.
---@return string[]
local function format_thinking_completed()
  M.state.is_streaming = false
  local lines = {}

  if M.state.thinking_buffer ~= "" then
    table.insert(lines, "── Thinking ──")

    local thought_lines = vim.split(M.state.thinking_buffer, "\n")
    for _, line in ipairs(thought_lines) do
      table.insert(lines, line)
    end

    table.insert(lines, "")
  end

  M.state.thinking_buffer = ""
  return lines
end

---Format assistant message.
---@param data table
---@return string[]
local function format_assistant(data)
  local lines = {}
  table.insert(lines, "── Assistant ──")

  local message = data.message
  if message and message.content then
    for _, content in ipairs(message.content) do
      if content.type == "text" and content.text then
        local text_lines = vim.split(content.text, "\n")
        for _, text_line in ipairs(text_lines) do
          table.insert(lines, text_line)
        end
      end
    end
  end

  table.insert(lines, "")
  return lines
end

---Format result message.
---@param data table
---@return string[]
local function format_result(data)
  local lines = {}

  local status = data.is_error and "Error" or "Success"
  local icon = data.is_error and "✗" or "✓"

  table.insert(lines, "── Result ──")
  table.insert(lines, icon .. " Status: " .. status)

  if data.duration_ms then
    local duration_s = data.duration_ms / 1000
    table.insert(lines, string.format("Duration: %.2fs", duration_s))
  end

  if data.duration_api_ms and data.duration_api_ms ~= data.duration_ms then
    local api_duration_s = data.duration_api_ms / 1000
    table.insert(lines, string.format("API Time: %.2fs", api_duration_s))
  end

  if data.request_id then
    table.insert(lines, "Request: " .. string.sub(data.request_id, 1, 8) .. "...")
  end

  table.insert(lines, "")
  return lines
end

---Format tool use message.
---@param data table
---@return string[]
local function format_tool_use(data)
  local lines = {}
  table.insert(lines, "── Tool: " .. (data.tool or "unknown") .. " ──")

  if data.input then
    table.insert(lines, "Input:")
    if type(data.input) == "table" then
      for k, v in pairs(data.input) do
        local value_str = type(v) == "string" and v or vim.inspect(v)
        table.insert(lines, "  " .. k .. ": " .. value_str)
      end
    else
      table.insert(lines, "  " .. tostring(data.input))
    end
  end

  table.insert(lines, "")
  return lines
end

---Format tool result message.
---@param data table
---@return string[]
local function format_tool_result(data)
  local lines = {}
  local icon = data.is_error and "✗" or "✓"
  table.insert(lines, "── Tool Result " .. icon .. " ──")

  if data.result then
    local result_str = type(data.result) == "string" and data.result or vim.inspect(data.result)
    local result_lines = vim.split(result_str, "\n")
    for i, line in ipairs(result_lines) do
      if i > 10 then
        table.insert(lines, "... (truncated)")
        break
      end
      table.insert(lines, line)
    end
  end

  table.insert(lines, "")
  return lines
end

---Format assistant text delta (streaming response).
---@param data table
---@return string[], boolean lines and whether this is a streaming update
local function format_assistant_delta(data)
  local lines = {}
  if data.text then
    table.insert(lines, data.text)
  end
  return lines, true
end

---@alias TypeHandler fun(data: table, result: SmithAgentParseResult): nil

---@type table<string, TypeHandler>
local type_handlers = {
  system = function(data, result)
    result.lines = format_system(data)
  end,

  user = function(data, result)
    result.lines = format_user(data)
  end,

  thinking = function(data, result)
    if data.subtype == "delta" then
      result.lines, result.replace_thinking = format_thinking_delta(data)
      result.is_streaming = true
    elseif data.subtype == "completed" then
      result.lines = format_thinking_completed()
    end
  end,

  assistant = function(data, result)
    if data.subtype == "delta" then
      result.lines, result.is_streaming = format_assistant_delta(data)
    else
      result.lines = format_assistant(data)
    end
  end,

  result = function(data, result)
    result.lines = format_result(data)
  end,

  tool_use = function(data, result)
    result.lines = format_tool_use(data)
  end,

  tool_result = function(data, result)
    result.lines = format_tool_result(data)
  end,
}

---@class SmithAgentParseResult
---@field lines string[]
---@field replace_thinking boolean
---@field is_streaming boolean
---@field type string|nil

---Parse a single JSON line from the agent stream.
---@param line string
---@return SmithAgentParseResult
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

---@class SmithAgentStreamState
---@field lines string[]
---@field thinking_start number|nil
---@field assistant_streaming_start number|nil
---@field assistant_buffer string

---Create a new stream state for tracking buffer updates.
---@return SmithAgentStreamState
function M.create_stream_state()
  return {
    lines = {},
    thinking_start = nil,
    assistant_streaming_start = nil,
    assistant_buffer = "",
  }
end

---@param stream_state SmithAgentStreamState
local function clear_thinking_lines(stream_state)
  if stream_state.thinking_start then
    while #stream_state.lines >= stream_state.thinking_start do
      table.remove(stream_state.lines)
    end
  end
end

---@alias StreamUpdateHandler fun(stream_state: SmithAgentStreamState, result: SmithAgentParseResult): nil

---@type table<string, StreamUpdateHandler>
local stream_update_handlers = {
  replace_thinking = function(stream_state, result)
    clear_thinking_lines(stream_state)
    if not stream_state.thinking_start then
      stream_state.thinking_start = #stream_state.lines + 1
    end
    vim.list_extend(stream_state.lines, result.lines)
  end,

  thinking_completed = function(stream_state, result)
    clear_thinking_lines(stream_state)
    vim.list_extend(stream_state.lines, result.lines)
    stream_state.thinking_start = nil
  end,

  assistant_streaming = function(stream_state, result)
    stream_state.assistant_buffer = stream_state.assistant_buffer .. result.lines[1]
  end,

  assistant_complete = function(stream_state, result)
    stream_state.assistant_buffer = ""
    stream_state.thinking_start = nil
    vim.list_extend(stream_state.lines, result.lines)
  end,

  default = function(stream_state, result)
    stream_state.thinking_start = nil
    vim.list_extend(stream_state.lines, result.lines)
  end,
}

---@param result SmithAgentParseResult
---@return string
local function get_stream_handler_key(result)
  if result.replace_thinking then
    return "replace_thinking"
  elseif result.type == "thinking" and not result.is_streaming then
    return "thinking_completed"
  elseif result.type == "assistant" and result.is_streaming then
    return "assistant_streaming"
  elseif result.type == "assistant" and not result.is_streaming then
    return "assistant_complete"
  else
    return "default"
  end
end

---Parse a line and update stream state.
---@param stream_state SmithAgentStreamState
---@param line string
---@return SmithAgentStreamState, boolean
function M.parse_and_update(stream_state, line)
  local result = M.parse_line(line)
  if #result.lines == 0 then
    return stream_state, false
  end

  local key = get_stream_handler_key(result)
  local handler = stream_update_handlers[key] or stream_update_handlers.default
  handler(stream_state, result)
  return stream_state, true
end

---Parse full output.
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
    session_id = M.state.session_id,
    model = M.state.model,
  }
end

return M
