local M = {}

M.chezmoi_files = function()
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local finders = require('telescope.finders')
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local result = vim.fn.split(vim.fn.system('chezmoi managed -x externals,dirs'))
  local displayer = require('telescope.pickers.entry_display').create({
    items = { {} },
  })
  local home = os.getenv('HOME')
  pickers
    .new({
      prompt_title = 'Chezmoi',

      finder = finders.new_table({
        results = result,
        entry_maker = function(entry_text)
          local entry = {}
          entry.value = entry_text
          entry.rel = entry_text
          entry.dst = home .. '/' .. entry_text
          entry.ordinal = entry_text
          entry.display = function(ent)
            return displayer({
              { ent.rel },
            })
          end
          return entry
        end,
      }),
      previewer = conf.grep_previewer({}),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if selection == nil then
            print('[telescope] Nothing currently selected')
            return
          end

          vim.fn.jobstart('chezmoi edit ' .. vim.fn.shellescape(selection.dst), {
            env = {
              CHEZMOI_NVIM = 'open',
              EDITOR = 'chezmoi-nvim',
            },
            on_stdout = function(_, out)
              local file = out[1]
              vim.cmd([[ echo " " ]])
              vim.cmd.edit(file)
              vim.b.chezmoi_target_path = selection.dst
            end,
            stdout_buffered = true,
          })
          actions.close(prompt_bufnr)
          vim.notify('Opening chezmoi file...', vim.log.levels.INFO, { title = 'Chezmoi' })
        end)
        return true
      end,
    }, {})
    :find()
end

return M
