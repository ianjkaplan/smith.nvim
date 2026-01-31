describe("smith.parser", function()
  local parser

  before_each(function()
    parser = require("smith.parser")
    parser.reset()
  end)

  describe("parse_line", function()
    it("should parse system init message", function()
      local json = vim.json.encode({
        type = "system",
        subtype = "init",
        model = "Claude 4.5 Opus",
        session_id = "a4987236-c77d-4786-9bcb-738804abd5a7",
        cwd = "/Users/test/projects",
        permissionMode = "default",
      })

      local result = parser.parse_line(json)

      assert.are.equal("system", result.type)
      assert.is_true(#result.lines > 0)
      assert.is_false(result.is_streaming)

      -- Check that model info is captured
      local info = parser.get_session_info()
      assert.are.equal("Claude 4.5 Opus", info.model)
    end)

    it("should parse user message", function()
      local json = vim.json.encode({
        type = "user",
        message = {
          role = "user",
          content = {
            { type = "text", text = "hello how are you" },
          },
        },
        session_id = "a4987236-c77d-4786-9bcb-738804abd5a7",
      })

      local result = parser.parse_line(json)

      assert.are.equal("user", result.type)
      assert.is_true(#result.lines > 0)
      -- Check that user text is in the output
      local found = false
      for _, line in ipairs(result.lines) do
        if line:match("hello how are you") then
          found = true
          break
        end
      end
      assert.is_true(found, "User message text should be in output")
    end)

    it("should parse thinking delta", function()
      local json = vim.json.encode({
        type = "thinking",
        subtype = "delta",
        text = "The user is just",
        session_id = "a4987236-c77d-4786-9bcb-738804abd5a7",
        timestamp_ms = 1769883985457,
      })

      local result = parser.parse_line(json)

      assert.are.equal("thinking", result.type)
      assert.is_true(result.is_streaming)
      assert.is_true(result.replace_thinking)
      assert.is_true(#result.lines > 0)
    end)

    it("should accumulate thinking deltas", function()
      parser.parse_line(vim.json.encode({
        type = "thinking",
        subtype = "delta",
        text = "Hello ",
        session_id = "test",
        timestamp_ms = 1,
      }))

      parser.parse_line(vim.json.encode({
        type = "thinking",
        subtype = "delta",
        text = "World",
        session_id = "test",
        timestamp_ms = 2,
      }))

      -- Check internal state has accumulated text
      assert.are.equal("Hello World", parser.state.thinking_buffer)
    end)

    it("should parse thinking completed", function()
      -- First add some thinking
      parser.parse_line(vim.json.encode({
        type = "thinking",
        subtype = "delta",
        text = "Test thinking",
        session_id = "test",
        timestamp_ms = 1,
      }))

      local json = vim.json.encode({
        type = "thinking",
        subtype = "completed",
        session_id = "test",
        timestamp_ms = 2,
      })

      local result = parser.parse_line(json)

      assert.are.equal("thinking", result.type)
      assert.is_false(result.is_streaming)
      -- Buffer should be cleared after completion
      assert.are.equal("", parser.state.thinking_buffer)
    end)

    it("should parse assistant message", function()
      local json = vim.json.encode({
        type = "assistant",
        message = {
          role = "assistant",
          content = {
            { type = "text", text = "Hello! I'm doing well, thanks for asking." },
          },
        },
        session_id = "test",
      })

      local result = parser.parse_line(json)

      assert.are.equal("assistant", result.type)
      assert.is_false(result.is_streaming)
      assert.is_true(#result.lines > 0)
    end)

    it("should parse result message", function()
      local json = vim.json.encode({
        type = "result",
        subtype = "success",
        duration_ms = 4702,
        duration_api_ms = 4702,
        is_error = false,
        result = "Test result",
        session_id = "test",
        request_id = "55b0edfa-14a1-4fd7-99d5-3e2e802c7aae",
      })

      local result = parser.parse_line(json)

      assert.are.equal("result", result.type)
      assert.is_true(#result.lines > 0)

      -- Check that duration is shown
      local found_duration = false
      for _, line in ipairs(result.lines) do
        if line:match("Duration") then
          found_duration = true
          break
        end
      end
      assert.is_true(found_duration, "Duration should be in output")
    end)

    it("should return empty result for invalid JSON", function()
      local result = parser.parse_line("not valid json")

      assert.is_nil(result.type)
      assert.are.equal(0, #result.lines)
    end)

    it("should return empty result for empty line", function()
      local result = parser.parse_line("")

      assert.is_nil(result.type)
      assert.are.equal(0, #result.lines)
    end)
  end)

  describe("parse_agent_stream", function()
    it("should parse full stream output", function()
      local raw_lines = {
        vim.json.encode({
          type = "system",
          subtype = "init",
          model = "Claude 4.5 Opus",
          session_id = "test",
          cwd = "/test",
          permissionMode = "default",
        }),
        vim.json.encode({
          type = "user",
          message = {
            role = "user",
            content = { { type = "text", text = "hello" } },
          },
          session_id = "test",
        }),
        vim.json.encode({
          type = "thinking",
          subtype = "delta",
          text = "Thinking...",
          session_id = "test",
          timestamp_ms = 1,
        }),
        vim.json.encode({
          type = "thinking",
          subtype = "completed",
          session_id = "test",
          timestamp_ms = 2,
        }),
        vim.json.encode({
          type = "assistant",
          message = {
            role = "assistant",
            content = { { type = "text", text = "Hello back!" } },
          },
          session_id = "test",
        }),
        vim.json.encode({
          type = "result",
          subtype = "success",
          duration_ms = 1000,
          is_error = false,
          result = "Done",
          session_id = "test",
          request_id = "req-123",
        }),
      }

      local formatted = parser.parse_agent_stream(raw_lines)

      assert.is_true(#formatted > 0)

      -- Verify different sections are present
      local has_system = false
      local has_user = false
      local has_thinking = false
      local has_assistant = false
      local has_result = false

      for _, line in ipairs(formatted) do
        if line:match("System") then
          has_system = true
        end
        if line:match("User") then
          has_user = true
        end
        if line:match("Thinking") then
          has_thinking = true
        end
        if line:match("Assistant") then
          has_assistant = true
        end
        if line:match("Result") then
          has_result = true
        end
      end

      assert.is_true(has_system, "Should have System section")
      assert.is_true(has_user, "Should have User section")
      assert.is_true(has_thinking, "Should have Thinking section")
      assert.is_true(has_assistant, "Should have Assistant section")
      assert.is_true(has_result, "Should have Result section")
    end)
  end)

  describe("reset", function()
    it("should clear all state", function()
      -- Set some state
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
