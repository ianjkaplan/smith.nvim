---@class Smith
---@field config SmithConfig
---@field history string[]
local M = {}

---@type SmithConfig
M.config = require("smith.config").defaults

---@type string[]
M.history = {}

---Main setup funciton for smith.nvim with user configuration
---@param opts? SmithConfig
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Set up user commands
  M._setup_commands()

  -- Set up keymaps if enabled
  if M.config.keymaps then
    M._setup_keymaps()
  end

  -- Set up autocommands if enabled
  if M.config.autocmds then
    M._setup_autocmds()
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

---Set up autocommands
function M._setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("Smith", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function()
      -- Add your autocmd logic here
    end,
  })
end

---Main plugin functionality - opens command palette with text pre-filled
---@param input string
function M.run(input)
  vim.ui.input({
    prompt = "Smith: ",
    default = input or "",
  }, function(value)
    if value == nil or value == "" then
      -- User cancelled or empty input
      return
    end

    -- Store for repeat functionality
    M._last_input = value

    -- Add to history
    table.insert(M.history, value)

    if M.config.notify then
      vim.notify("Smith: " .. value, vim.log.levels.INFO)
    end
  end)
end

---Show history list
function M.show_history()
  if #M.history == 0 then
    vim.notify("Smith: No history yet", vim.log.levels.INFO)
    return
  end

  -- Create items with index tracking (reverse order so newest is first)
  local items = {}
  for i = #M.history, 1, -1 do
    table.insert(items, { text = M.history[i], index = i })
  end

  vim.ui.select(items, {
    prompt = "Smith History:",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      M.open_float(choice.text, choice.index)
    end
  end)
end

---Open a floating window with the given content
---@param content string
---@param history_index? number Index in history (for deletion)
function M.open_float(content, history_index)
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
    if history_index then
      table.remove(M.history, history_index)
      vim.api.nvim_win_close(win, true)
      vim.notify("Smith: Deleted from history", vim.log.levels.INFO)
    end
  end, { buffer = buf, silent = true })
end

---Get the current configuration
---@return SmithConfig
function M.get_config()
  return M.config
end

return M
