-- Prevent loading plugin twice
if vim.g.loaded_smith then
  return
end
vim.g.loaded_smith = true

-- Set minimum Neovim version
if vim.fn.has("nvim-0.8.0") == 0 then
  vim.api.nvim_err_writeln("smith.nvim requires Neovim >= 0.8.0")
  return
end

-- Expose global vim variables for configuration before setup
vim.g.smith_loaded = false
vim.g.smith_config = nil
