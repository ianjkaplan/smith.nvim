-- Luacheck configuration for Neovim plugin
std = "luajit"
cache = true

-- Neovim globals
globals = {
  "vim",
}

-- Plenary/busted test globals
read_globals = {
  "describe",
  "it",
  "before_each",
  "after_each",
  "assert",
  "pending",
  "spy",
  "stub",
  "mock",
}

-- Ignore common false positives
ignore = {
  "212", -- unused argument (common in callbacks)
}

-- Ignore line length (stylua handles formatting)
max_line_length = false

-- Ignore unused self warnings for methods
self = false

-- Files to exclude
exclude_files = {
  ".luacheckrc",
}
