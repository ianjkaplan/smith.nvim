describe("smith.parsers.codex", function()
  local parser

  before_each(function()
    parser = require("smith.parsers.codex")
    parser.reset()
  end)

  it("should parse thread started", function()
    local result = parser.parse_line(vim.json.encode({
      type = "thread.started",
      thread_id = "019c6680-694c-75f2-8555-fb9764ca5ad8",
    }))

    assert.are.equal("thread.started", result.type)
    assert.is_true(#result.lines > 0)

    local info = parser.get_session_info()
    assert.are.equal("019c6680-694c-75f2-8555-fb9764ca5ad8", info.session_id)
  end)

  it("should parse reasoning and agent messages from item.completed", function()
    local reasoning = parser.parse_line(vim.json.encode({
      type = "item.completed",
      item = { type = "reasoning", text = "Thinking through this change" },
    }))

    local assistant = parser.parse_line(vim.json.encode({
      type = "item.completed",
      item = { type = "agent_message", text = "ok" },
    }))

    assert.are.equal("item.completed", reasoning.type)
    assert.is_true(#reasoning.lines > 0)
    assert.is_true(#assistant.lines > 0)
  end)

  it("should parse turn.completed usage", function()
    local result = parser.parse_line(vim.json.encode({
      type = "turn.completed",
      usage = {
        input_tokens = 10,
        cached_input_tokens = 2,
        output_tokens = 5,
      },
    }))

    assert.are.equal("turn.completed", result.type)
    assert.is_true(#result.lines > 0)
  end)

  it("should ignore unknown item types", function()
    local result = parser.parse_line(vim.json.encode({
      type = "item.completed",
      item = { type = "unknown", text = "ignored" },
    }))

    assert.are.equal("item.completed", result.type)
    assert.are.equal(0, #result.lines)
  end)

  it("should return empty result for invalid json", function()
    local result = parser.parse_line("not valid json")
    assert.is_nil(result.type)
    assert.are.equal(0, #result.lines)
  end)
end)
