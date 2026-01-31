-- Set minimum Neovim version
if vim.fn.has("nvim-0.8.0") == 0 then
  vim.api.nvim_err_writeln("smith.nvim requires Neovim >= 0.8.0")
  return
end
