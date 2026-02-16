local smith = require("smith")
local config = require("smith.config")

describe("smith.nvim", function()
  before_each(function()
    -- Reset state before each test
    vim.g.smith_loaded = nil
    vim.g.smith_config = nil
    smith.config = vim.deepcopy(config.defaults)
  end)

  describe("setup", function()
    it("should use default config when called without options", function()
      smith.setup()

      assert.is_true(smith.config.enabled)
      assert.is_true(smith.config.keymaps)
      assert.are.equal("codex", smith.config.provider)
    end)

    it("should merge user config with defaults", function()
      smith.setup({
        keymaps = false,
        provider = "agent",
      })

      assert.is_true(smith.config.enabled)
      assert.is_false(smith.config.keymaps)
      assert.are.equal("agent", smith.config.provider)
    end)

    it("should accept claude as a provider", function()
      smith.setup({
        provider = "claude",
      })

      assert.are.equal("claude", smith.config.provider)
    end)

    it("should create user command", function()
      smith.setup()

      local commands = vim.api.nvim_get_commands({})
      assert.is_not_nil(commands.Smith)
    end)
  end)

  -- TODO: mock run tests
  -- describe("run", function()
  --   it("should return default message when called without input", function()
  --     smith.setup({ notify = false })
  --
  --     local result = smith.run("")
  --
  --     assert.equal("Hello from smith.nvim!", result)
  --   end)
  --
  --   it("should return input when provided", function()
  --     smith.setup({ notify = false })
  --
  --     local result = smith.run("custom message")
  --
  --     assert.equal("custom message", result)
  --   end)
  -- end)

  describe("get_config", function()
    it("should return current configuration", function()
      smith.setup({ keymaps = false })

      local cfg = smith.get_config()

      assert.is_false(cfg.keymaps)
      assert.is_true(cfg.enabled)
      assert.are.equal("codex", cfg.provider)
    end)
  end)

  describe("config validation", function()
    it("should validate correct config", function()
      local validated = config.validate(config.defaults)

      assert.is_true(validated.enabled)
      assert.is_true(validated.keymaps)
      assert.are.equal("codex", validated.provider)
    end)
  end)
end)
