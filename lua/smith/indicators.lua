---@class SmithIndicators
local M = {}

---@class SmithIndicator
---@field job_index number
---@field bufnr number
---@field extmark_id number
---@field line number

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

  -- Extmark line is 0-indexed, context.finish is 1-indexed
  -- Place after the selection end line
  local line = context.finish - 1

  -- Clamp to valid line range
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line >= line_count then
    line = line_count - 1
  end

  -- Create extmark with virtual line below
  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, M._namespace, line, 0, {
    virt_lines = { { { "Smith #" .. job_index .. " working...", "Comment" } } },
    virt_lines_above = false,
  })

  -- Store indicator state
  M._indicators[job_id] = {
    job_index = job_index,
    bufnr = bufnr,
    extmark_id = extmark_id,
    line = line,
  }
end

---Update indicator to show completion status, then remove after delay
---@param job_id number
---@param status "completed"|"failed"|"cancelled"
function M.done(job_id, status)
  local indicator = M._indicators[job_id]
  if not indicator then
    return
  end

  -- Check if buffer is still valid
  if not vim.api.nvim_buf_is_valid(indicator.bufnr) then
    M._indicators[job_id] = nil
    return
  end

  -- Determine completion text and highlight
  local text, hl
  if status == "completed" then
    text = "Smith #" .. indicator.job_index .. " complete"
    hl = "DiagnosticOk"
  elseif status == "failed" then
    text = "Smith #" .. indicator.job_index .. " failed"
    hl = "DiagnosticError"
  else
    text = "Smith #" .. indicator.job_index .. " cancelled"
    hl = "DiagnosticWarn"
  end

  -- Update extmark with completion status
  vim.api.nvim_buf_set_extmark(indicator.bufnr, M._namespace, indicator.line, 0, {
    id = indicator.extmark_id,
    virt_lines = { { { text, hl } } },
    virt_lines_above = false,
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
