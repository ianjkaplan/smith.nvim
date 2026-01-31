---@class SmithIndicators
local M = {}

local timer_mod = require("smith.timer")

---@class SmithIndicator
---@field job_index number
---@field bufnr number
---@field extmark_id number
---@field line number
---@field timer userdata|nil

---@type table<number, SmithIndicator> job_id -> indicator state
M._indicators = {}

---Namespace for all smith indicator extmarks
M._namespace = vim.api.nvim_create_namespace("smith_indicators")

---Show an indicator for a job with visual context
---@param job_id number
---@param job_index number
---@param context SmithContext
function M.show(job_id, job_index, context)
  -- Get the buffer from the context location
  local bufnr = vim.fn.bufnr(context.location)
  if bufnr == -1 then
    -- Buffer not loaded, try current buffer
    bufnr = vim.api.nvim_get_current_buf()
  end

  -- Extmark line is 0-indexed, context.start is 1-indexed
  -- Place above the selection start line
  local line = context.start - 1

  -- Clamp to valid line range
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line >= line_count then
    line = line_count - 1
  end
  if line < 0 then
    line = 0
  end

  -- Create extmark with virtual line above
  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M._namespace, line, 0, {
    virt_lines = { { { "Smith #" .. job_index .. " working...", "Comment" } } },
    virt_lines_above = true,
  })

  -- Store indicator state
  M._indicators[job_id] = {
    job_index = job_index,
    bufnr = bufnr,
    extmark_id = extmark_id,
    line = line,
    timer = nil,
  }

  -- Start animation timer to cycle dots
  M._indicators[job_id].timer = timer_mod.create_dot_animation(function(dot_count)
    local indicator = M._indicators[job_id]
    if not indicator or not vim.api.nvim_buf_is_valid(indicator.bufnr) then
      return
    end

    local dots = string.rep(".", dot_count)
    local text = "Smith #" .. indicator.job_index .. " working" .. dots

    vim.api.nvim_buf_set_extmark(indicator.bufnr, M._namespace, indicator.line, 0, {
      id = indicator.extmark_id,
      virt_lines = { { { text, "Comment" } } },
      virt_lines_above = true,
    })
  end)
end

---Update indicator to show completion status, then remove after delay
---@param job_id number
---@param status string
function M.done(job_id, status)
  local indicator = M._indicators[job_id]
  if not indicator then
    return
  end

  -- Stop animation timer
  timer_mod.stop(indicator.timer)
  indicator.timer = nil

  -- Check if buffer is still valid
  if not vim.api.nvim_buf_is_valid(indicator.bufnr) then
    M._indicators[job_id] = nil
    return
  end

  -- Status display configuration
  local status_config = {
    completed = { suffix = "complete", hl = "DiagnosticOk" },
    failed = { suffix = "failed", hl = "DiagnosticError" },
    cancelled = { suffix = "cancelled", hl = "DiagnosticWarn" },
  }

  local config = status_config[status] or status_config.cancelled
  local text = "Smith #" .. indicator.job_index .. " " .. config.suffix
  local hl = config.hl

  -- Update extmark with completion status
  vim.api.nvim_buf_set_extmark(indicator.bufnr, M._namespace, indicator.line, 0, {
    id = indicator.extmark_id,
    virt_lines = { { { text, hl } } },
    virt_lines_above = true,
  })

  -- Remove after delay (2 seconds)
  vim.defer_fn(function()
    M.remove(job_id)
  end, 2000)
end

---Remove an indicator
---@param job_id number
function M.remove(job_id)
  local indicator = M._indicators[job_id]
  if not indicator then
    return
  end

  -- Stop animation timer
  timer_mod.stop(indicator.timer)
  indicator.timer = nil

  -- Check if buffer is still valid before removing extmark
  if vim.api.nvim_buf_is_valid(indicator.bufnr) then
    pcall(vim.api.nvim_buf_del_extmark, indicator.bufnr, M._namespace, indicator.extmark_id)
  end

  M._indicators[job_id] = nil
end

---Remove all indicators
function M.clear()
  for job_id, _ in pairs(M._indicators) do
    M.remove(job_id)
  end
end

---Check if a job has an active indicator
---@param job_id number
---@return boolean
function M.has_indicator(job_id)
  return M._indicators[job_id] ~= nil
end

return M
