# telescope-completion.nvim

A [telescope.nvim][] extension that allows you to pick Insert mode completion
with Telescope.

[telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim

<img src="https://raw.githubusercontent.com/illia-shkroba/files/master/readme-telescope-completion.gif" alt="screenshot" width="800"/>

## Installation

This is an example for [Lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
{
  "illia-shkroba/telescope-completion.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("telescope").load_extension "completion"
  end,
}
```

## Usage

```lua
-- This plugin exposes `completion` picker that could only be used when there is
-- a *popup-menu* visible. You can check if popup-menu is visible by using
-- `vim.fn.pumvisible` function (see `:h popupmenu-completion` for details).
-- Here is an example that enables `completion` to be used with **CTRL-Q**:
vim.keymap.set("i", [[<C-q>]], function()
  if vim.fn.pumvisible() == 1 then
    vim.cmd.Telescope "completion"
    return ""
  else
    return [[<C-q>]]
  end
end, { expr = true })
```

The plugin currently does not remove the text inserted with **CTRL-N** or
**CTRL-P**. Thus, it is better to use **CTRL-P** immediately after triggering
the completion (in order to select none).
