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
    local completion = require("telescope").load_extension "completion"

    vim.keymap.set("i", [[<C-z>]], function()
      if vim.fn.pumvisible() == 1 then
        return completion.completion_expr()
      else
        return [[<C-z>]]
      end
    end, { expr = true, desc = "List popup-menu completion in Telescope" })
  end,
}
```

## Usage

* Use any completion in insert mode that you normally use. For example: **CTRL-X CTRL-L**.
* Hit **CTRL-Z** when the *popup-menu* appears (or any other binding that you have set in `config`).
    - Text that you have inserted so far will be removed and a __Telescope Picker__ will appear.
* Choose any completion and hit **Enter** or **CTRL-Y** to accept the completion.

## How it works

This plugin exposes `completion` picker and a helper function `completion_expr`. The picker and the
function could only be used when there is a *popup-menu* visible. You can check if *popup-menu* is
visible by using `vim.fn.pumvisible` function (see `:h popupmenu-completion` for details).

`completion_expr` helper function should be used instead of the `completion` picker, because the
helper function removes a current selection within the *popup-menu*. If you want to use the picker
instead, you would have to remove a current selection within the *popup-menu* manually with a help
of **CTRL-N** or **CTRL-P**. The `completion_expr` helper function does that for you. If you use
non-default bindings for going up and down within a *popup-menu*, you can pass the bindings like
this:

```lua
completion.completion_expr {
  popup_menu_up_key = [[<C-k>]],
  popup_menu_down_key = [[<C-j>]],
}
```

When you accept a completion, the plugin __attempts__ to remove a text that you have typed so far
before inserting the completion. An `inserted` field is not implemented yet within
`vim.fn.complete_info` (as of `v0.11.0-dev`). Thus, the plugin compares a selected completion to
a text typed so far. If the typed text "matches" the selected completion, the plugin substitutes the
typed text with the selected completion. This approach _might not work sometimes_, but it _works
most of the times_.
