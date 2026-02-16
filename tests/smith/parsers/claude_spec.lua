describe("smith.parsers.claude", function()
  local parser

  before_each(function()
    parser = require("smith.parsers.claude")
    parser.reset()
  end)

  describe("parse_line", function()
    it("should parse system init message", function()
      local json = vim.json.encode({
        type = "system",
        subtype = "init",
        model = "claude-sonnet-4-5-20250929",
        session_id = "a4987236-c77d-4786-9bcb-738804abd5a7",
        cwd = "/Users/test/projects",
        permissionMode = "default",
      })

      local result = parser.parse_line(json)

      assert.are.equal("system", result.type)
      assert.is_true(#result.lines > 0)
      assert.is_false(result.is_streaming)

      local info = parser.get_session_info()
      assert.are.equal("claude-sonnet-4-5-20250929", info.model)
    end)

    it("should parse thinking delta and completion", function()
      local delta = parser.parse_line(vim.json.encode({
        type = "thinking",
        subtype = "delta",
        text = "Thinking",
        session_id = "test",
      }))
      assert.are.equal("thinking", delta.type)
      assert.is_true(delta.is_streaming)

      local completed = parser.parse_line(vim.json.encode({
        type = "thinking",
        subtype = "completed",
        session_id = "test",
      }))
      assert.are.equal("thinking", completed.type)
      assert.is_false(completed.is_streaming)
      assert.are.equal("", parser.state.thinking_buffer)
    end)

    it("should parse assistant and result messages", function()
      local assistant = parser.parse_line(vim.json.encode({
        type = "assistant",
        message = {
          role = "assistant",
          content = {
            { type = "text", text = "Hello back!" },
          },
        },
      }))

      local result = parser.parse_line(vim.json.encode({
        type = "result",
        is_error = false,
        duration_ms = 1000,
      }))

      assert.are.equal("assistant", assistant.type)
      assert.are.equal("result", result.type)
      assert.is_true(#assistant.lines > 0)
      assert.is_true(#result.lines > 0)
    end)

    it("should return empty result for invalid json", function()
      local result = parser.parse_line("not valid json")
      assert.is_nil(result.type)
      assert.are.equal(0, #result.lines)
    end)
  end)

  describe("parse_stream", function()
    it("should parse full stream output", function()
      local raw_lines = {
        vim.json.encode({
          type = "system",
          subtype = "init",
          model = "claude-sonnet-4-5-20250929",
          session_id = "test",
          cwd = "/test",
          permissionMode = "default",
        }),
        vim.json.encode({
          type = "assistant",
          message = {
            role = "assistant",
            content = { { type = "text", text = "Hello back!" } },
          },
        }),
        vim.json.encode({
          type = "result",
          subtype = "success",
          duration_ms = 1000,
          is_error = false,
          request_id = "req-123",
        }),
      }

      local formatted = parser.parse_stream(raw_lines)

      assert.is_true(#formatted > 0)
      local has_system = false
      local has_assistant = false
      local has_result = false

      for _, line in ipairs(formatted) do
        if line:match("System") then
          has_system = true
        end
        if line:match("Assistant") then
          has_assistant = true
        end
        if line:match("Result") then
          has_result = true
        end
      end

      assert.is_true(has_system)
      assert.is_true(has_assistant)
      assert.is_true(has_result)
    end)
  end)

  describe("reset", function()
    it("should clear state", function()
      parser.state.thinking_buffer = "test"
      parser.state.session_id = "test-id"
      parser.state.model = "test-model"
      parser.state.is_streaming = true

      parser.reset()

      assert.are.equal("", parser.state.thinking_buffer)
      assert.is_nil(parser.state.session_id)
      assert.is_nil(parser.state.model)
      assert.is_false(parser.state.is_streaming)
    end)
  end)
end)
