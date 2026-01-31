<div align="center">

# smith.nvim

### A Neovim plugin for managing multiple background AI agents from within Neovim. Spawn, monitor, and interact with concurrent agent sessions without leaving your editor.

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%2010+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>

## Features

- Spawn and manage multiple background agent instances
- Real-time streaming output with formatted display
- Visual selection context support for code-aware prompts
- History management with live updates for running agents
- Default keymaps for quick access
- Floating window UI for viewing agent output

## Requirements

- Neovim >= 0.10.0
- `cursor-agent` CLI tool available in PATH

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
  enabled = true,           -- Enable the plugin
  autocmds = false,         -- Enable autocommands
  debug = false,            -- Enable debug mode
  keymaps = true,           -- Enable default keymaps
  keymap_prefix = "<leader>m", -- Prefix for keymaps
})
```

## Usage

### Commands

```vim
:Smith [message]    # Open command palette with optional pre-filled message
```

### Default Keymaps

All keymaps use the configured prefix (default: `<leader>m`):

| Mode          | Keymap       | Description                                       |
| ------------- | ------------ | ------------------------------------------------- |
| Normal        | `<leader>mm` | Open command palette                              |
| Visual        | `<leader>mm` | Open with selection as context                    |
| Visual        | `<leader>mM` | Open palette (selection stored but not auto-used) |
| Normal/Visual | `<leader>mc` | Clear completed agents from history               |
| Normal        | `<leader>mr` | Repeat last command                               |
| Normal        | `<leader>ml` | Show history list                                 |

### Floating Window Keymaps

When viewing agent output or history:

| Keymap  | Description               |
| ------- | ------------------------- |
| `q`     | Close window              |
| `<Esc>` | Close window              |
| `d`     | Delete entry from history |
| `b`     | Go back to history list   |

### Visual Selection Context

When using `<leader>mm` in visual mode, the selected text is automatically included as context in your prompt. The agent receives:

- The selected text content
- File path where the selection originated
- Line numbers of the selection

## API

### Setup

```lua
require("smith").setup(opts)
```

Initialize the plugin with optional configuration.

### Run

```lua
require("smith").run(input, context)
```

Open the command palette with optional pre-filled input and context.

**Parameters:**

- `input` (string): Pre-filled text for the command palette
- `context` (table, optional): Context from visual selection
  - `content` (string): The selected text
  - `location` (string): File path
  - `start` (number): Starting line number
  - `finish` (number): Ending line number

### Show History

```lua
require("smith").show_history()
```

Display the history list of all agent sessions.

### Get Config

```lua
require("smith").get_config()
```

Returns the current configuration table.

## History

Agent sessions are tracked in history with the following statuses:

- `running` - Agent is actively working
- `completed` - Agent finished successfully
- `failed` - Agent exited with an error
- `cancelled` - Agent was manually stopped

Running agents show live streaming updates when viewed in the history viewer.

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
