---@class SmithAgent
---@field jobs table<number, SmithJob>
local M = {}

---@class SmithJob
---@field id number
---@field cmd string[]
---@field stdout string[]
---@field stderr string[]
---@field status "running"|"completed"|"failed"|"cancelled"
---@field exit_code number|nil
---@field on_stdout fun(data: string[])|nil
---@field on_stderr fun(data: string[])|nil
---@field on_exit fun(job: SmithJob)|nil

---@type table<number, SmithJob>
M.jobs = {}

---@class SmithJobOpts
---@field text string
---@field cwd? string
---@field env? table<string, string>
---@field on_stdout? fun(data: string[])
---@field on_stderr? fun(data: string[])
---@field on_exit? fun(job: SmithJob)

---Dispatch a new job
---@param opts SmithJobOpts
---@return number|nil job_id
function M.dispatch(opts)
  ---@type SmithJob
  local job = {
    id = 0,
    cmd = {
      "agent",
      "-p",
      "--output-format=stream-json",
      opts.text,
    },
    stdout = {},
    stderr = {},
    status = "running",
    exit_code = nil,
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
      vim.schedule(function()
        if job.on_exit then
          job.on_exit(job)
        end
      end)
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
    vim.notify("Smith Agent: Failed to start job", vim.log.levels.ERROR)
    return nil
  end

  job.id = job_id
  M.jobs[job_id] = job

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

---Wait for a job to complete (blocking)
---@param job_id number
---@param timeout? number Timeout in milliseconds
---@return boolean success
function M.wait(job_id, timeout)
  local result = vim.fn.jobwait({ job_id }, timeout or -1)
  return result[1] ~= -1
end

return M
