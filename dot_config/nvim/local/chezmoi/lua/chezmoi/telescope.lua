local M = {}

local e = vim.fn.shellescape

local function trim_string(text)
  text, _ = text:gsub('^%s*(.-)%s*$', '%1')
  return text
end

M.chezmoi_files = function()
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local finders = require('telescope.finders')
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local source_path = trim_string(vim.fn.system('chezmoi source-path'))
  local hidden_files = vim.fn.split(vim.fn.system('find ' .. e(source_path) .. ' -type f  -iname ".*"'))
  local encrypted_files = vim.fn.split(vim.fn.system('chezmoi managed -i encrypted'))
  local result = vim.fn.split(vim.fn.system('chezmoi managed -x externals,dirs,encrypted'))
  for _, file in pairs(hidden_files) do
    result[#result + 1] = file
  end
  for _, file in pairs(encrypted_files) do
    result[#result + 1] = '[enc]' .. file
  end

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
          entry.chezmoi_cfg = false
          entry.view = entry_text
          if entry_text:sub(1, 5) == '[enc]' then
            entry_text = entry_text:sub(6)
            entry.view = entry_text .. ' [encrypted ]'
          end
          if entry_text:sub(1, #source_path) == source_path then
            entry.chezmoi_cfg = true
            entry.view = '[src]/' .. entry_text:sub(#source_path + 2)
            entry_text = entry_text:sub(#home + 2)
          end
          entry.value = home .. '/' .. entry_text
          entry.ordinal = entry_text .. ' ' .. entry.view
          entry.display = function(ent)
            return displayer({
              { ent.view },
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

          actions.close(prompt_bufnr)

          if selection.chezmoi_cfg then
            vim.cmd.edit(selection.value)
            return
          end
          vim.fn.jobstart('chezmoi edit ' .. e(selection.value), {
            env = {
              CHEZMOI_NVIM = 'open',
              EDITOR = 'chezmoi-nvim',
            },
            on_stdout = function(_, out)
              local file = out[1]
              vim.cmd([[ echo " " ]])
              vim.cmd.edit(file)
              vim.b.chezmoi_target_path = selection.value
            end,
            stdout_buffered = true,
          })
          vim.notify('Opening chezmoi file...', vim.log.levels.INFO, { title = 'Chezmoi' })
        end)
        return true
      end,
    }, {})
    :find()
end

return M
