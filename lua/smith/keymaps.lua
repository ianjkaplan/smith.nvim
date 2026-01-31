---@class SmithKeymaps
local M = {}

---Get the visual selection text
---@return string
local function get_visual_selection()
  local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
  local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))

  if start_row == 0 then
    return ""
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #lines == 0 then
    return ""
  end

  -- Adjust for partial line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end

  return table.concat(lines, "\n")
end

---Open command palette (normal mode)
function M.open_palette()
  local smith = require("smith")
  smith.run("")
end

---Open command palette with selected text as context
function M.open_palette_with_selection()
  local smith = require("smith")
  local selection = get_visual_selection()
  smith.run(selection)
end

---Open command palette without auto-inserting selection
---Selection is available but not automatically used
function M.open_palette_selection_available()
  local smith = require("smith")
  -- Store selection for later use but don't auto-insert
  M._stored_selection = get_visual_selection()
  smith.run("")
end

---Get stored selection (for use when selection is available but not auto-inserted)
---@return string
function M.get_stored_selection()
  return M._stored_selection or ""
end

---Clear stored selection and cancel current operation
function M.clear()
  M._stored_selection = nil
  vim.notify("Smith: Cleared", vim.log.levels.INFO)
end

---Repeat last command
function M.repeat_last()
  local smith = require("smith")
  if smith._last_input then
    smith.run(smith._last_input)
  else
    vim.notify("Smith: No previous command to repeat", vim.log.levels.WARN)
  end
end

---Show history list
function M.show_history()
  local smith = require("smith")
  smith.show_history()
end

---Set up keymaps
---@param opts? { prefix?: string }
function M.setup(opts)
  opts = opts or {}
  local prefix = opts.prefix or "<leader>m"

  -- Normal mode: open command palette
  vim.keymap.set("n", prefix .. "m", M.open_palette, {
    desc = "Smith: Open command palette",
  })

  -- Visual mode: open with selected text as context
  vim.keymap.set("v", prefix .. "m", M.open_palette_with_selection, {
    desc = "Smith: Open with selection",
  })

  -- Visual mode: open palette (selection available but not auto-inserted)
  vim.keymap.set("v", prefix .. "M", M.open_palette_selection_available, {
    desc = "Smith: Open palette (selection available)",
  })

  -- Clear/cancel
  vim.keymap.set({ "n", "v" }, prefix .. "c", M.clear, {
    desc = "Smith: Clear/cancel",
  })

  -- Repeat last command
  vim.keymap.set("n", prefix .. "r", M.repeat_last, {
    desc = "Smith: Repeat last command",
  })

  -- Show history list
  vim.keymap.set("n", prefix .. "l", M.show_history, {
    desc = "Smith: Show history list",
  })
end

return M
