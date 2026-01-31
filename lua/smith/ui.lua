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

return M
