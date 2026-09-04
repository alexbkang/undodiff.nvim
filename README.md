# undodiff.nvim

Neovim plugin that wraps the `undotree.nvim` plugin and uses Neovim's
native diff mode to show undo history.

## Usage
Run `:UndodiffToggle` to open a session on the current buffer; run it
again to close it.

## Configuration
`setup()` is optional — the plugin works out of the box with defaults.

```lua
-- default options
require("undodiff").setup({
	treesitter = true,
	number = true,
	relativenumber = false,
	signcolumn = "no",
})
```

## Installation
**vim.pack.add** (Neovim 0.12+)

```lua
vim.pack.add("https://github.com/alexbkang/undodiff")
```

## Features
- Treesitter support
- Show undo history in a split view (tree | snapshot | source).

## Architecture

```
   UndodiffToggle
         │
         ▼
     ┌ packadd undotree ◄── tree (left)
     ├ copy buffer → snapshot (right)
     └ diffthis source ↔ snapshot
```
