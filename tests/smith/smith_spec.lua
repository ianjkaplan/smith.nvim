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
      assert.is_false(smith.config.autocmds)
      assert.is_false(smith.config.debug)
    end)

    it("should merge user config with defaults", function()
      smith.setup({
        debug = true,
      })

      assert.is_true(smith.config.enabled)
      assert.is_false(smith.config.autocmds)
      assert.is_true(smith.config.debug)
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
      smith.setup({ debug = true })

      local cfg = smith.get_config()

      assert.is_true(cfg.debug)
      assert.is_true(cfg.enabled)
    end)
  end)

  describe("config validation", function()
    it("should validate correct config", function()
      local valid, err = config.validate(config.defaults)

      assert.is_true(valid)
      assert.is_nil(err)
    end)
  end)
end)
