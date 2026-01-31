---@class Smith
---@field config SmithConfig
local M = {}

local ui = require("smith.ui")
local agent = require("smith.agent")
local history = require("smith.history")

---@type SmithConfig
M.config = require("smith.config").defaults

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
  ui.input("Smith: ", input, function(value)
    -- Store for repeat functionality
    M._last_input = value

    -- Add to history and get index
    local history_index = history.add(value)

    -- Dispatch the agent job with the input
    agent.dispatch({
      text = value,
      on_stdout = function(data)
        history.append_output(history_index, data)
      end,
      on_stderr = function(data)
        history.append_output(history_index, data)
      end,
      on_exit = function(job)
        history.set_status(history_index, job.status)
        if job.status == "completed" then
          vim.notify("Smith: Job completed", vim.log.levels.INFO)
        else
          vim.notify("Smith: Job failed with exit code " .. (job.exit_code or "unknown"), vim.log.levels.ERROR)
        end
      end,
    })
  end)
end

---Show history list
function M.show_history()
  history.show(ui, function(entry, index)
    -- Build content: show input as header, then output
    local lines = { "Input: " .. entry.input, "Status: " .. entry.status, string.rep("─", 40) }
    if #entry.output > 0 then
      vim.list_extend(lines, entry.output)
    else
      table.insert(lines, "(no output)")
    end
    M._open_float(table.concat(lines, "\n"), index)
  end)
end

---Open a floating window with the given content
---@param content string
---@param history_index? number Index in history (for deletion)
function M._open_float(content, history_index)
  ui.open_float(content, history_index, function(index)
    history.remove(index)
  end)
end

---Get the current configuration
---@return SmithConfig
function M.get_config()
  return M.config
end

return M
