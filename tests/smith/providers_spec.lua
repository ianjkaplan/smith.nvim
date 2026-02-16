local providers = require("smith.providers")
local defaults = require("smith.config").defaults

describe("smith.providers", function()
  local config

  before_each(function()
    config = vim.deepcopy(defaults)
  end)

  it("should resolve codex as default provider", function()
    local provider, provider_cfg = providers.get_active(config)

    assert.are.equal("codex", provider)
    assert.are.equal("codex", provider_cfg.cmd)
  end)

  it("should build codex command with full-auto args", function()
    local provider, cmd = providers.build_cmd(config, { text = "test prompt" })

    assert.are.equal("codex", provider)
    assert.are.equal("codex", cmd[1])
    assert.are.equal("exec", cmd[2])
    assert.are.equal("--json", cmd[3])
    assert.are.equal("--full-auto", cmd[4])
    assert.are.equal(true, cmd[#cmd]:match("test prompt") ~= nil)
  end)

  it("should build agent command when provider is agent", function()
    config.provider = "agent"

    local provider, cmd = providers.build_cmd(config, { text = "test prompt" })

    assert.are.equal("agent", provider)
    assert.are.equal("agent", cmd[1])
    assert.are.equal("-p", cmd[2])
    assert.are.equal("--output-format=stream-json", cmd[3])
  end)

  it("should build claude command when provider is claude", function()
    config.provider = "claude"

    local provider, cmd = providers.build_cmd(config, { text = "test prompt" })

    assert.are.equal("claude", provider)
    assert.are.equal("claude", cmd[1])
    assert.are.equal("-p", cmd[2])
    assert.are.equal("--output-format=stream-json", cmd[3])
    assert.are.equal("--verbose", cmd[4])
  end)

  it("should append context details to prompt", function()
    local _, cmd = providers.build_cmd(config, {
      text = "refactor this",
      context = {
        content = "local x = 1",
        location = "lua/smith/test.lua",
        start = 10,
        finish = 10,
      },
    })

    local prompt = cmd[#cmd]
    assert.are.equal(true, prompt:match("Context from lua/smith/test.lua %(lines 10%-10%)") ~= nil)
    assert.are.equal(true, prompt:match("local x = 1") ~= nil)
  end)
end)
