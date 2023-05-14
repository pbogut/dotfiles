local putils = require('telescope.previewers.utils')
local conf = require('telescope.config').values
local tmux = require('tmuxctl')
local utils = require('telescope.utils')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local actions = require('telescope.actions')
local sorters = require('telescope.sorters')
local previewers = require('telescope.previewers')
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

local close_session = function(finder)
  return function(prompt_bufnr)
    local selection = action_state.get_selected_entry(prompt_bufnr)
    if selection.session_name then
      tmux.close_session(selection.session_name)
      selection.session_name = ''

      local picker = action_state.get_current_picker(prompt_bufnr)
      local selection_row = picker:get_selection_row()
      local callbacks = { unpack(picker._completion_callbacks) } -- shallow copy
      picker:register_completion_callback(function(self)
        self:set_selection(selection_row)
        self._completion_callbacks = callbacks
      end)

      picker:refresh(finder, { reset_prompt = false })
    end
  end
end

local select_project = function(opts)
  opts = opts or {}
  local projects = utils.get_os_command_output({ 'ls-project', '--full-path' })

  local lazy_dir = vim.fn.stdpath('data') .. '/lazy/'
  for _, plugin in pairs(utils.get_os_command_output({ 'ls', '-1' }, lazy_dir)) do
    projects[#projects + 1] = lazy_dir .. plugin
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
  local finder = finders.new_table({
    results = results,
    entry_maker = function(entry)
      entry.value = entry.path
      entry.ordinal = entry.session_name .. ' ' .. entry.path
      entry.display = make_display
      return entry
    end,
  })

  local previewer = previewers.new_buffer_previewer({
    title = 'Git Stash Preview',
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, _)
      putils.job_maker(
        {
          'git',
          '-C',
          entry.value,
          '--no-pager',
          'log',
          '--graph',
          --[[ '--pretty=format:%h -%d %s (%cr)', ]]
          '--pretty=format:%h %s (%cr)',
          '--abbrev-commit',
          '--date=relative',
        },
        self.state.bufnr,
        {
          value = entry.value,
          bufname = self.state.bufname,
          cwd = opts.cwd,
        }
      )
    end,
  })

  pickers
    .new(opts or {}, {
      prompt_title = 'Projects',
      previewer = previewer,
      finder = finder,
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(switch_project)

        map('i', '<c-x>', close_session(finder))
        map('n', '<c-x>', close_session(finder))

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
