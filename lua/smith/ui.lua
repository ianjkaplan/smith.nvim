---@class SmithUI
local M = {}

---Open a floating window with the given content
---@param content string
---@param history_index? number Index in history (for deletion)
---@param on_delete? fun(index: number) Callback when item is deleted
function M.open_float(content, history_index, on_delete)
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Split content into lines
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Calculate window size (80% of editor)
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)

  -- Calculate position (centered)
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  -- Window options
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Smith (q: close, d: delete) ",
    title_pos = "center",
  }

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set buffer options
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  -- Set window options for proper text display
  vim.api.nvim_set_option_value("wrap", true, { win = win })
  vim.api.nvim_set_option_value("linebreak", true, { win = win })

  -- Close on q or Escape
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })

  -- Delete from history on d
  vim.keymap.set("n", "d", function()
    if history_index and on_delete then
      on_delete(history_index)
      vim.api.nvim_win_close(win, true)
      vim.notify("Smith: Deleted from history", vim.log.levels.INFO)
    end
  end, { buffer = buf, silent = true })
end

---Show an input prompt
---@param prompt string
---@param default? string
---@param on_confirm fun(value: string)
function M.input(prompt, default, on_confirm)
  vim.ui.input({
    prompt = prompt,
    default = default or "",
  }, function(value)
    if value == nil or value == "" then
      -- User cancelled or empty input
      return
    end
    on_confirm(value)
  end)
end

---Show a selection list
---@param items table[] Items with text and index fields
---@param prompt string
---@param on_select fun(choice: table)
function M.select(items, prompt, on_select)
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      on_select(choice)
    end
  end)
end

---@class StreamingWindow
---@field buf number Buffer handle
---@field win number Window handle
---@field lines string[] Current lines in buffer

---Open a streaming floating window that can be updated
---@param title? string Window title
---@param history_index? number Index in history (for deletion)
---@param on_delete? fun(index: number) Callback when item is deleted
---@param on_back? fun() Callback to go back to list view
---@return StreamingWindow|nil
function M.open_streaming_float(title, history_index, on_delete, on_back)
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Calculate window size (80% of editor)
  local editor_ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(editor_ui.width * 0.8)
  local height = math.floor(editor_ui.height * 0.8)

  -- Calculate position (centered)
  local row = math.floor((editor_ui.height - height) / 2)
  local col = math.floor((editor_ui.width - width) / 2)

  -- Window options
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = title or " Smith (streaming...) ",
    title_pos = "center",
  }

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set buffer options
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

  -- Set window options for proper text display
  vim.api.nvim_set_option_value("wrap", true, { win = win })
  vim.api.nvim_set_option_value("linebreak", true, { win = win })

  -- Close on q or Escape
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })

  -- Delete from history on d
  vim.keymap.set("n", "d", function()
    if history_index and on_delete then
      on_delete(history_index)
      vim.api.nvim_win_close(win, true)
      vim.notify("Smith: Deleted from history", vim.log.levels.INFO)
    end
  end, { buffer = buf, silent = true })

  -- Back to list on b
  vim.keymap.set("n", "b", function()
    if on_back then
      vim.api.nvim_win_close(win, true)
      on_back()
    end
  end, { buffer = buf, silent = true })

  ---@type StreamingWindow
  return {
    buf = buf,
    win = win,
    lines = {},
  }
end

---Update a streaming window with new lines
---@param streaming_win StreamingWindow
---@param lines string[]
---@param scroll_to_bottom? boolean
function M.update_streaming_float(streaming_win, lines, scroll_to_bottom)
  if not vim.api.nvim_win_is_valid(streaming_win.win) then
    return
  end

  streaming_win.lines = lines

  vim.api.nvim_set_option_value("modifiable", true, { buf = streaming_win.buf })
  vim.api.nvim_buf_set_lines(streaming_win.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = streaming_win.buf })

  -- Scroll to bottom if requested
  if scroll_to_bottom then
    local line_count = vim.api.nvim_buf_line_count(streaming_win.buf)
    vim.api.nvim_win_set_cursor(streaming_win.win, { line_count, 0 })
  end
end

---Close a streaming window
---@param streaming_win StreamingWindow
function M.close_streaming_float(streaming_win)
  if vim.api.nvim_win_is_valid(streaming_win.win) then
    vim.api.nvim_win_close(streaming_win.win, true)
  end
end

---Check if streaming window is still valid
---@param streaming_win StreamingWindow
---@return boolean
function M.is_streaming_valid(streaming_win)
  return vim.api.nvim_win_is_valid(streaming_win.win)
end

return M
