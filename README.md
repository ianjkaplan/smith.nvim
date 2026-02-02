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

## Configuration

```lua
require("smith").setup({
  enabled = true,              -- Enable the plugin
  keymaps = true,              -- Enable default keymaps
  keymap_prefix = "<leader>m", -- Prefix for keymaps
})
```

## Usage

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
