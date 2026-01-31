# smith.nvim

> **Work in Progress** - This plugin is under active development.

A Neovim plugin for managing multiple background AI agents from within Neovim. Spawn, monitor, and interact with multiple concurrent agent sessions without leaving your editor.

## Features (Planned)

- Spawn and manage multiple background agent instances
- Monitor agent status and output in real-time
- Send tasks to agents and receive results
- Switch between active agent sessions
- Unified interface for different agent backends

## Requirements

- Neovim >= 0.10.0

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "iankaplan/smith.nvim",
  config = function()
    require("smith").setup()
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "iankaplan/smith.nvim",
  config = function()
    require("smith").setup()
  end,
}
```

## Configuration

```lua
require("smith").setup({
  enabled = true,   -- Enable the plugin
  notify = true,    -- Show notifications
  autocmds = false, -- Enable autocommands
  debug = false,    -- Enable debug mode
})
```

## Usage

```vim
:Smith [message]    " Coming soon: spawn agents, list sessions, send commands
```

## Status

This plugin is in early development. The API and commands are subject to change.

## Vim Globals

After setup, the following globals are available:

- `vim.g.loaded_smith` - `true` if plugin file was loaded
- `vim.g.smith_loaded` - `true` if setup() was called
- `vim.g.smith_config` - Current configuration table

## Development

### Prerequisites

- [luacheck](https://github.com/mpeterv/luacheck): `luarocks install luacheck`
- [stylua](https://github.com/JohnnyMorganz/StyLua): `cargo install stylua`

### Commands

```bash
make deps          # Install test dependencies
make test          # Run all tests
make lint          # Run luacheck
make format        # Format code with stylua
make format-check  # Check formatting
make check         # Run all checks (lint + format + test)
make clean         # Clean temporary files
```

### Running a specific test file

```bash
make test-file FILE=tests/smith/smith_spec.lua
```

## Contributing

This is an early-stage project. Contributions, ideas, and feedback are welcome!

## License

MIT
