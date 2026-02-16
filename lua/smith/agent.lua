---@class SmithAgent
---@field jobs table<number, SmithJob>
local M = {}

local indicators = require("smith.indicators")
local providers = require("smith.providers")

---@class SmithJob
---@field id number
---@field index number
---@field cmd string[]
---@field stdout string[]
---@field stderr string[]
---@field status "running"|"completed"|"failed"|"cancelled"
---@field exit_code number|nil
---@field context SmithContext|nil
---@field provider SmithProviderName
---@field on_stdout fun(data: string[])|nil
---@field on_stderr fun(data: string[])|nil
---@field on_exit fun(job: SmithJob)|nil

---@class SmithContext
---@field content string The selected text or code snippet to provide as context. This is the raw text content that will be included in the agent prompt, typically obtained from a visual selection or buffer range.
---@field location string File path or buffer identifier where the context originated. Used to give the agent information about the file being edited (e.g., "lua/smith/agent.lua").
---@field start number Starting line number of the selection (1-indexed). Corresponds to the first line of the selected content in the original buffer.
---@field finish number Ending line number of the selection (1-indexed). Corresponds to the last line of the selected content in the original buffer.

---@type table<number, SmithJob>
M.jobs = {}

---@class SmithJobOpts
---@field text string
---@field config ValidatedSmithConfig
---@field context? SmithContext
---@field cwd? string
---@field env? table<string, string>
---@field on_stdout? fun(data: string[])
---@field on_stderr? fun(data: string[])
---@field on_exit? fun(job: SmithJob)

---Dispatch a new job
---@param opts SmithJobOpts
---@return number|nil job_id
function M.dispatch(opts)
  local provider, cmd = providers.build_cmd(opts.config, opts)

  ---@type SmithJob
  local job = {
    id = 0,
    cmd = cmd,
    index = vim.tbl_count(M.jobs) + 1,
    stdout = {},
    stderr = {},
    status = "running",
    exit_code = nil,
    context = opts.context,
    provider = provider,
    on_stdout = opts.on_stdout,
    on_stderr = opts.on_stderr,
    on_exit = opts.on_exit,
  }

  local job_opts = {
    on_stdout = function(_, data)
      if data then
        local filtered = vim.tbl_filter(function(line)
          return line ~= ""
        end, data)
        if #filtered > 0 then
          vim.list_extend(job.stdout, filtered)
          vim.schedule(function()
            if job.on_stdout then
              job.on_stdout(filtered)
            end
          end)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        local filtered = vim.tbl_filter(function(line)
          return line ~= ""
        end, data)
        if #filtered > 0 then
          vim.list_extend(job.stderr, filtered)
          vim.schedule(function()
            if job.on_stderr then
              job.on_stderr(filtered)
            end
          end)
        end
      end
    end,
    on_exit = function(_, exit_code)
      job.exit_code = exit_code
      job.status = exit_code == 0 and "completed" or "failed"
      if job.on_exit then
        job.on_exit(job)
      end
    end,
    stdout_buffered = false,
    stderr_buffered = false,
    pty = true,
  }

  if opts.cwd then
    job_opts.cwd = opts.cwd
  end

  if opts.env then
    job_opts.env = opts.env
  end

  local job_id = vim.fn.jobstart(job.cmd, job_opts)

  if job_id <= 0 then
    vim.notify("Agent Smith: Failed to start", vim.log.levels.ERROR)
    return nil
  end

  job.id = job_id
  M.jobs[job_id] = job
  vim.notify(string.format("Smith #%d working (%s)", job.index, job.provider), vim.log.levels.INFO)

  -- Show indicator if we have visual context
  if opts.context then
    indicators.show(job_id, job.index, opts.context)
  end

  return job_id
end

---Stop a running job
---@param job_id number
---@return boolean success
function M.stop(job_id)
  local job = M.jobs[job_id]
  if not job then
    return false
  end

  if job.status ~= "running" then
    return false
  end

  vim.fn.jobstop(job_id)
  job.status = "cancelled"

  return true
end

---Get a job by id
---@param job_id number
---@return SmithJob|nil
function M.get(job_id)
  return M.jobs[job_id]
end

---Get all jobs
---@return table<number, SmithJob>
function M.get_all()
  return M.jobs
end

---Get all running jobs
---@return SmithJob[]
function M.get_running()
  local running = {}
  for _, job in pairs(M.jobs) do
    if job.status == "running" then
      table.insert(running, job)
    end
  end
  return running
end

---Clear completed/failed/cancelled jobs from the list
function M.clear_finished()
  for id, job in pairs(M.jobs) do
    if job.status ~= "running" then
      M.jobs[id] = nil
    end
  end
end

---Send input to a running job
---@param job_id number
---@param data string
---@return boolean success
function M.send(job_id, data)
  local job = M.jobs[job_id]
  if not job or job.status ~= "running" then
    return false
  end

  vim.fn.chansend(job_id, data)
  return true
end

return M
