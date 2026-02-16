---@class Smith
---@field config ValidatedSmithConfig
local M = {}

local ui = require("smith.ui")
local agent = require("smith.agent")
local history = require("smith.history")
local parser = require("smith.parser")
local indicators = require("smith.indicators")

---@type ValidatedSmithConfig
M.config = vim.deepcopy(require("smith.config").defaults)

---Main setup funciton for smith.nvim with user configuration
---@param opts? SmithConfig
function M.setup(opts)
  local merged = vim.tbl_deep_extend("force", M.config, opts or {})
  M.config = require("smith.config").validate(merged)

  -- Skip setup if plugin is disabled
  if not M.config.enabled then
    return
  end

  -- Set up user commands
  M._setup_commands()

  -- Set up keymaps if enabled
  if M.config.keymaps then
    M._setup_keymaps()
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

---Set up keymaps
function M._setup_keymaps()
  local keymaps = require("smith.keymaps")
  keymaps.setup({ prefix = M.config.keymap_prefix })
end

---@type table<number, table> Active viewers for history entries (history_index -> viewer state)
M._active_viewers = {}

---Format the Query box header for a history entry
---@param input string The query input text
---@param status "running"|"completed"|"failed"|"cancelled" The job status
---@return string[] lines The formatted header lines
local function format_query_box(input, status)
  local status_icon = status == "completed" and "✓"
    or status == "failed" and "✗"
    or status == "running" and "…"
    or "⊘"

  return {
    "╭─ Query ──────────────────────────────────────╮",
    "│ " .. input,
    "│ Status: " .. status_icon .. " " .. status,
    "╰──────────────────────────────────────────────╯",
    "",
  }
end

---Main plugin functionality - opens command palette with text pre-filled
---@param input string
---@param context? SmithContext
function M.run(input, context)
  ui.input("Smith: ", input, function(value)
    -- Store for repeat functionality
    M._last_input = value

    -- Add to history and get index
    local history_index = history.add(value, M.config.provider)

    -- Dispatch the agent job with the input
    agent.dispatch({
      text = value,
      config = M.config,
      context = context,
      on_stdout = function(data)
        history.append_output(history_index, data)
        -- Update any active viewer for this entry
        M._update_viewer(history_index)

        -- reload buffers with changes
        vim.cmd("checktime")
      end,
      on_stderr = function(data)
        history.append_output(history_index, data)
        M._update_viewer(history_index)
      end,
      on_exit = function(job)
        history.set_status(history_index, job.status)
        M._update_viewer(history_index)

        -- Update indicator to show completion status
        if job.context then
          indicators.done(job.id, job.status)
        end

        if job.status == "completed" then
          vim.notify(string.format("Smith #%d completed", job.index), vim.log.levels.INFO)
        else
          vim.notify(
            string.format("Smith #%d failed with exit code ", job.index) .. (job.exit_code or "unknown"),
            vim.log.levels.ERROR
          )
        end
      end,
    })
  end)
end

---Update an active viewer if one exists for this history entry
---@param history_index number
function M._update_viewer(history_index)
  local viewer = M._active_viewers[history_index]
  if not viewer then
    return
  end

  -- Check if window is still valid
  if not ui.is_streaming_valid(viewer.streaming_win) then
    M._active_viewers[history_index] = nil
    return
  end

  local entry = history.get(history_index)
  if not entry then
    return
  end

  if entry.status ~= "running" then
    -- Job finished - rebuild entire buffer with updated status
    local status_icon = entry.status == "completed" and "✓" or "✗"

    -- Re-parse all output into fresh state with updated header
    local provider = entry.provider or "agent"
    local fresh_state = parser.create_stream_state(provider)
    fresh_state.lines = format_query_box(entry.input, entry.status)
    for _, line in ipairs(entry.output) do
      fresh_state = parser.parse_and_update(fresh_state, line, provider)
    end

    -- Add footer
    table.insert(fresh_state.lines, "")
    table.insert(fresh_state.lines, "─── " .. status_icon .. " " .. entry.status .. " ───")

    ui.update_streaming_float(viewer.streaming_win, fresh_state.lines, true)

    -- Remove from active viewers since streaming is done
    M._active_viewers[history_index] = nil
  else
    -- Still running - incrementally parse new output
    local provider = viewer.provider or entry.provider or "agent"
    for i = viewer.parsed_lines + 1, #entry.output do
      viewer.stream_state = parser.parse_and_update(viewer.stream_state, entry.output[i], provider)
      viewer.parsed_lines = i
    end

    ui.update_streaming_float(viewer.streaming_win, viewer.stream_state.lines, true)
  end
end

---Show history list
function M.show_history()
  history.show(ui, function(entry, index)
    M._open_history_viewer(entry, index)
  end)
end

---Open a history entry viewer with live streaming support
---@param entry SmithHistoryEntry
---@param index number
function M._open_history_viewer(entry, index)
  -- Reset parser for this entry
  local provider = entry.provider or "agent"
  parser.reset(provider)

  -- Create stream state and parse existing output
  local stream_state = parser.create_stream_state(provider)
  stream_state.lines = format_query_box(entry.input, entry.status)

  -- Parse existing output
  for _, line in ipairs(entry.output) do
    stream_state = parser.parse_and_update(stream_state, line, provider)
  end

  -- Determine window title
  local title = entry.status == "running" and " Smith (q: close, b: back) " or " Smith (q: close, d: delete, b: back) "

  -- Open streaming window
  local streaming_win = ui.open_streaming_float(title, index, function(idx)
    history.remove(idx)
    M._active_viewers[idx] = nil
  end, function()
    -- on_back - return to history list
    M._active_viewers[index] = nil
    M.show_history()
  end)

  if not streaming_win then
    return
  end

  -- Build display lines
  local display_lines = vim.deepcopy(stream_state.lines)
  if entry.status ~= "running" then
    local status_icon = entry.status == "completed" and "✓" or "✗"
    table.insert(display_lines, "")
    table.insert(display_lines, "─── " .. status_icon .. " " .. entry.status .. " ───")
  end

  -- Initial display
  ui.update_streaming_float(streaming_win, display_lines, false)

  -- If still running, register as active viewer for live updates
  if entry.status == "running" then
    M._active_viewers[index] = {
      streaming_win = streaming_win,
      stream_state = stream_state,
      parsed_lines = #entry.output,
      provider = provider,
    }
  end
end

---Get the current configuration
---@return ValidatedSmithConfig
function M.get_config()
  return M.config
end

return M
