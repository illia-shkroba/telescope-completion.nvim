local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local string_utils = require "telescope._extensions.completion.string"
local themes = require "telescope.themes"
local utils = require "telescope.utils"

local remove_inserted = function(completions, buffer, cursor)
  -- The following implementation could be simplified when `inserted` field
  -- would become available in the output of `vim.fn.complete_info`.
  --
  -- Since there is no `inserted` field currently available, the
  -- `common_prefix` is used to find a common prefix for a list of completions.
  -- Then the text on the left side of the current cursor position is matched
  -- with for the common prefix that was found. If the text "partially" matches
  -- the common prefix (see `ends_with_prefix_of`), then the text is assumed to
  -- be `inserted` by the user before triggering the completion.
  local prefix = string_utils.common_prefix(completions)
  local row, end_column = cursor[1] - 1, cursor[2]
  local begin_column = end_column - #prefix
  if begin_column < 0 then
    begin_column = 0
  end

  local lines = vim.api.nvim_buf_get_text(
    buffer,
    row,
    begin_column,
    row,
    end_column,
    {}
  )

  if #prefix > 0 and #lines > 0 then
    local offset = string_utils.ends_with_prefix_of(lines[1], prefix)
    if offset ~= nil then
      vim.api.nvim_buf_set_text(
        buffer,
        row,
        begin_column + offset - 1,
        row,
        end_column,
        {}
      )
      return { row = row, column = begin_column + offset - 1 }
    end
  end
  return nil
end

local paste_completion = function(
  prompt_buffer,
  completions,
  completed_buffer,
  cursor
)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.paste_register"
    return
  end

  local row, column = cursor[1] - 1, cursor[2]
  local lines =
    vim.api.nvim_buf_get_lines(completed_buffer, row, row + 1, false)
  local cursor_at_end_of_line = #lines > 0 and #lines[1] == column

  local inserted_location = remove_inserted(
    completions,
    completed_buffer,
    cursor
  ) or { row = row, column = column }
  actions.close(prompt_buffer)

  -- For some reason cursor's column is shifted by +1 inside of select_default
  -- action. Thus, the cursor has to be shifted to its original position.
  vim.cmd.normal(tostring(inserted_location.column + 1) .. "|")

  vim.api.nvim_put({ selection[1] }, "c", cursor_at_end_of_line, true)
end

local completion = function(opts)
  opts = vim.tbl_deep_extend(
    "keep",
    opts or {},
    themes.get_cursor { previewer = false }
  )

  local completions = vim.tbl_map(function(x)
    return x.word
  end, vim.fn.complete_info({ "items" }).items)
  local completed_buffer = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())

  vim.schedule(function()
    pickers
      .new(opts, {
        prompt_title = "Completions",
        finder = finders.new_table {
          results = completions,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(_, map)
          local function select_default(prompt_buffer)
            return paste_completion(
              prompt_buffer,
              completions,
              completed_buffer,
              cursor
            )
          end
          actions.select_default:replace(select_default)
          map({ "n", "i" }, "<c-y>", select_default)
          map({ "n", "i" }, "<c-e>", actions.close)
          return true
        end,
      })
      :find()
  end)
  vim.cmd.stopinsert()
end

local function completion_expr(opts)
  opts = vim.tbl_deep_extend(
    "keep",
    opts or {},
    { popup_menu_up_key = [[<C-p>]], popup_menu_down_key = [[<C-n>]] }
  )

  vim.schedule(function()
    vim.cmd.Telescope "completion"
  end)

  local info = vim.fn.complete_info { "items", "selected" }
  if info.selected < #info.items / 2 then
    return string.rep(opts.popup_menu_up_key, info.selected + 1)
  else
    return string.rep(opts.popup_menu_down_key, #info.items - info.selected)
  end
end

return require("telescope").register_extension {
  setup = function() end,
  exports = {
    -- To be called via `:Telescope completion`. It should only be used when:
    -- `vim.fn.pumvisible() == 1`.
    completion = completion,
    -- To be called in `vim.keymap.set` with `expr = true`. It should only be
    -- used when: `vim.fn.pumvisible() == 1`.
    completion_expr = completion_expr,
  },
}
