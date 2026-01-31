---@class SmithHistoryEntry
---@field input string
---@field output string[]
---@field status "running"|"completed"|"failed"|"cancelled"

---@class SmithHistory
---@field items SmithHistoryEntry[]
local M = {}

---@type SmithHistoryEntry[]
M.items = {}

---Add an item to history
---@param input string
---@return number index The index of the new entry
function M.add(input)
  ---@type SmithHistoryEntry
  local entry = {
    input = input,
    output = {},
    status = "running",
  }
  table.insert(M.items, entry)
  return #M.items
end

---Update an entry's output
---@param index number
---@param lines string[]
function M.append_output(index, lines)
  local entry = M.items[index]
  if entry then
    vim.list_extend(entry.output, lines)
  end
end

---Update an entry's status
---@param index number
---@param status "running"|"completed"|"failed"|"cancelled"
function M.set_status(index, status)
  local entry = M.items[index]
  if entry then
    entry.status = status
  end
end

---Get an entry by index
---@param index number
---@return SmithHistoryEntry|nil
function M.get(index)
  return M.items[index]
end

---Remove an item from history by index
---@param index number
function M.remove(index)
  table.remove(M.items, index)
end

---Get all history items
---@return SmithHistoryEntry[]
function M.get_all()
  return M.items
end

---Get history count
---@return number
function M.count()
  return #M.items
end

---Check if history is empty
---@return boolean
function M.is_empty()
  return #M.items == 0
end

---Clear all history
function M.clear()
  M.items = {}
end

---Show history list in UI
---@param ui table The UI module
---@param on_select fun(entry: SmithHistoryEntry, index: number) Callback when item is selected
function M.show(ui, on_select)
  if M.is_empty() then
    vim.notify("Smith: No history yet", vim.log.levels.INFO)
    return
  end

  -- Create items with index tracking (reverse order so newest is first)
  local items = {}
  for i = #M.items, 1, -1 do
    local entry = M.items[i]
    local status_icon = entry.status == "completed" and "✓"
      or entry.status == "failed" and "✗"
      or entry.status == "running" and "…"
      or "⊘"
    table.insert(items, {
      text = string.format("[%s] %s", status_icon, entry.input),
      entry = entry,
      index = i,
    })
  end

  ui.select(items, "Smith History:", function(choice)
    on_select(choice.entry, choice.index)
  end)
end

return M
