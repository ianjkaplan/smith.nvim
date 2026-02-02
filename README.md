<div align="center">

# smith.nvim

### A Neovim plugin for managing multiple background AI agents from within Neovim. Spawn, monitor, and interact with concurrent agent sessions without leaving your editor.

[![Release](https://img.shields.io/github/v/release/ianjkaplan/smith.nvim?style=for-the-badge&color=cba6f7)](https://github.com/ianjkaplan/smith.nvim/releases)
[![License](https://img.shields.io/badge/License-MIT-94e2d5.svg?style=for-the-badge)](LICENSE)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%2010+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

_"Mr. Anderson, please sit down."_
— Agent Smith

</div>

## Features

- Spawn and manage multiple background agent instances
- Real-time streaming output
- Visual selection context support for code-aware prompts
- History management with live updates for running agents
- Floating window UI for viewing agent output

## Requirements

- Neovim >= 0.10.0
- `cursor-agent` CLI tool available in PATH

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "ianjkaplan/smith.nvim",
}
```

### Default Options

These are the default values. You only need to include options you want to change:

```lua
opts = {
  -- Enable the plugin
  enabled = true,
  -- Enable default keymaps
  keymaps = true,
  -- Prefix for all keymaps (e.g., <leader>mm, <leader>mc, etc.)
  keymap_prefix = "<leader>m",
}
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
