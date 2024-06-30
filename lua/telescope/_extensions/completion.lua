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
    end
  end
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

  remove_inserted(completions, completed_buffer, cursor)
  actions.close(prompt_buffer)
  vim.api.nvim_paste(selection[1], true, -1)
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
        attach_mappings = function()
          actions.select_default:replace(function(prompt_buffer)
            return paste_completion(
              prompt_buffer,
              completions,
              completed_buffer,
              cursor
            )
          end)
          return true
        end,
      })
      :find()
  end)
  vim.cmd.stopinsert()
end

return require("telescope").register_extension {
  setup = function() end,
  exports = {
    completion = completion,
  },
}
