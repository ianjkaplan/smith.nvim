---@diagnostic disable: undefined-field -- uv timers are not fully typed by neodev
---@class SmithTimer
local M = {}

---Create an animated timer that calls update_fn with cycling dot count
---@param update_fn fun(dot_count: number)
---@return userdata|nil timer
function M.create_dot_animation(update_fn)
  -- fallback to vim.loop if uv is not available
  local uv = vim.uv or vim.loop
  local timer = uv.new_timer()
  local dot_count = 3

  timer:start(
    500,
    500,
    vim.schedule_wrap(function()
      dot_count = (dot_count % 3) + 1
      update_fn(dot_count)
    end)
  )

  return timer
end

---@param timer userdata|nil
function M.stop(timer)
  if timer then
    timer:stop()
    timer:close()
  end
end

return M
