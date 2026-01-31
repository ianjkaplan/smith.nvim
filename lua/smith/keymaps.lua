---@class SmithKeymaps
local M = {}

---Get the visual selection as SmithContext (requires Neovim 0.10+)
---@return SmithContext|nil
local function get_visual_selection_context()
  local start_pos = vim.fn.getpos("v") -- start of visual selection
  local end_pos = vim.fn.getpos(".") -- current cursor position

  local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.mode() })

  if #lines == 0 then
    return nil
  end

  -- Normalize line numbers (selection could be upward or downward)
  local start_line = math.min(start_pos[2], end_pos[2])
  local end_line = math.max(start_pos[2], end_pos[2])

  -- Exit visual mode
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)

  return {
    content = table.concat(lines, "\n"),
    location = vim.api.nvim_buf_get_name(0),
    start = start_line,
    finish = end_line,
  }
end

---Open command palette (normal mode)
function M.open_palette()
  local smith = require("smith")
  smith.run("")
end

---Open command palette with selected text as context
function M.open_palette_with_selection()
  local smith = require("smith")
  local context = get_visual_selection_context()
  smith.run("", context)
end

---Open command palette without auto-inserting selection
---Selection is available but not automatically used
function M.open_palette_selection_available()
  local smith = require("smith")
  -- Store selection for later use but don't auto-insert
  M._stored_context = get_visual_selection_context()
  smith.run("")
end

---Get stored context (for use when selection is available but not auto-inserted)
---@return SmithContext|nil
function M.get_stored_context()
  return M._stored_context
end

---Clear stored context and completed jobs from history
function M.clear()
  M._stored_context = nil
  local history = require("smith.history")
  local count = history.clear_completed()
  if count > 0 then
    vim.notify("Agents Smith: Cleared " .. count .. " completed agents(s)", vim.log.levels.INFO)
  else
    vim.notify("Agents Smith: No completed agents to clear", vim.log.levels.INFO)
  end
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
