local tmux = require('tmuxctl')
local utils = require('telescope.utils')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local actions = require('telescope.actions')
local sorters = require('telescope.sorters')
local action_state = require('telescope.actions.state')

local switch_project = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    print('[telescope] Nothing currently selected')
    return
  end

  local pr_path = selection.path
  actions.close(prompt_bufnr)

  tmux.switch_to_path(pr_path)
end

local hl_and_filter_sorter = function(opts)
  opts = opts or {}
  local fzy = opts.fzy_mod or require('telescope.algos.fzy')

  local sorter = sorters.new({
    filter_function = function(_, prompt, entry)
      if fzy.has_match(prompt, entry.session_name .. entry.short_path) then
        return 1
      else
        return -1
      end
    end,
    scoring_function = function()
      return 1
    end,
    highlighter = function(_, prompt, display)
      return fzy.positions(prompt, display)
    end,
  })

  return sorter
end

local select_project = function(opts)
  opts = opts or {}
  local projects = utils.get_os_command_output({ 'ls-project', '--full-path' })

  local pack_str = vim.fn.stdpath('data') .. '/site/pack/packer/start/'
  local pack_opt = vim.fn.stdpath('data') .. '/site/pack/packer/opt/'
  for _, plugin in pairs(utils.get_os_command_output({ 'ls', '-1' }, pack_str)) do
    projects[#projects + 1] = pack_str .. plugin
  end
  for _, plugin in pairs(utils.get_os_command_output({ 'ls', '-1' }, pack_opt)) do
    projects[#projects + 1] = pack_opt .. plugin
  end

  local results = {}
  local path_session = tmux.get_path_session_name_map()
  local ses_width = 0

  for _, ses_path in pairs(path_session) do
    ses_width = math.max(ses_width, ses_path.session_name:len())
  end

  local displayer = require('telescope.pickers.entry_display').create({
    separator = ' ',
    items = {
      { width = ses_width },
      {},
    },
  })

  local make_display = function(entry)
    return displayer({
      { entry.session_name, 'TelescopeResultsIdentifier' },
      { entry.short_path },
    })
  end

  local result_sess = {}
  local current_session = tmux.name_session(vim.fn.getcwd())
  for _, project in pairs(projects) do
    local pack_path = vim.fn.stdpath('data') .. '/site/pack/packer/'
    local sess = path_session[project] or { session_name = '' }
    local entry = {
      path = project,
      short_path = project:gsub('.*%/Projects%/', ''):gsub('^' .. pack_path, ''),
      session_name = sess.session_name,
    }
    -- exclude current session from list
    if entry.session_name ~= current_session then
      if sess.path then
        result_sess[#result_sess + 1] = entry
      else
        results[#results + 1] = entry
      end
    end
  end

  local idx = 1
  for _, sess_entry in ipairs(result_sess) do
    table.insert(results, idx, sess_entry)
    idx = idx + 1
  end

  pickers
    .new(opts or {}, {
      prompt_title = 'Projects',
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          entry.value = entry.path
          entry.ordinal = entry.session_name .. ' ' .. entry.path
          entry.display = make_display
          return entry
        end,
      }),
      sorter = hl_and_filter_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(switch_project)
        return true
      end,
    })
    :find()
end

return require('telescope').register_extension({
  exports = {
    ls_projects = select_project,
    ['tmux-projects'] = select_project,
  },
})
