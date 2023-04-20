local tmux = require('tmuxctl')
local strings = require('plenary.strings')
local previewers = require('telescope.previewers')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local actions = require('telescope.actions')
local utils = require('telescope.utils')
local action_set = require('telescope.actions.set')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local git_worktree = require('git-worktree')
local git = require('githelper')

local force_next_deletion = false

local get_worktree_path = function(prompt_bufnr)
  local selection = action_state.get_selected_entry(prompt_bufnr)
  return selection.path
end

local switch_worktree = function(prompt_bufnr)
  local worktree_path = get_worktree_path(prompt_bufnr)
  actions.close(prompt_bufnr)
  if worktree_path ~= nil then
    tmux.switch_to_path(worktree_path)
  end
end

local toggle_forced_deletion = function()
  -- redraw otherwise the message is not displayed when in insert mode
  if force_next_deletion then
    print('The next deletion will not be forced')
    vim.fn.execute('redraw')
  else
    print('The next deletion will be forced')
    vim.fn.execute('redraw')
    force_next_deletion = true
  end
end

local delete_success_handler = function()
  force_next_deletion = false
end

local delete_failure_handler = function()
  print('Deletion failed, use <C-f> to force the next deletion')
end

local ask_to_confirm_deletion = function(forcing)
  if forcing then
    return vim.fn.input('Force deletion of worktree? [y/n]: ')
  end

  return vim.fn.input('Delete worktree? [y/n]: ')
end

local confirm_deletion = function(forcing)
  if not git_worktree._config.confirm_telescope_deletions then
    return true
  end

  local confirmed = ask_to_confirm_deletion(forcing)

  if string.sub(string.lower(confirmed), 0, 1) == 'y' then
    return true
  end

  print("Didn't delete worktree")
  return false
end

local close_session = function(finder)
  return function(prompt_bufnr)
    local selection = action_state.get_selected_entry(prompt_bufnr)
    if selection.session then
      tmux.close_session(selection.session)
      selection.session = ''

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

local delete_worktree = function(prompt_bufnr)
  if not confirm_deletion() then
    return
  end

  local worktree_path = get_worktree_path(prompt_bufnr)
  actions.close(prompt_bufnr)
  if worktree_path ~= nil then
    git_worktree.delete_worktree(worktree_path, force_next_deletion, {
      on_failure = delete_failure_handler,
      on_success = delete_success_handler,
    })
  end
end

local create_input_prompt = function(cb)
  local subtree = vim.fn.input('Path to subtree > ')
  cb(subtree)
end

local create_worktree = function(opts)
  opts = opts or {}
  opts.attach_mappings = function()
    actions.select_default:replace(function(prompt_bufnr, _)
      local selected_entry = action_state.get_selected_entry()
      local current_line = action_state.get_current_line()

      actions.close(prompt_bufnr)

      local branch = selected_entry ~= nil and selected_entry.value or current_line

      if branch == nil then
        return
      end

      create_input_prompt(function(name)
        if name == '' then
          name = branch
        end
        git_worktree.create_worktree(name, branch)
      end)
    end)

    -- do we need to replace other default maps?

    return true
  end
  require('telescope.builtin').git_branches(opts)
end

local telescope_git_worktree = function(opts)
  opts = opts or {}
  local output = utils.get_os_command_output({ 'git', 'worktree', 'list' })
  local results = {}
  local results_with_session = {}
  local widths = {
    session = 0,
    path = 0,
    sha = 0,
    branch = 0,
  }
  local session_map = tmux.get_path_session_name_map()

  local is_bare, bare_path = git.is_bare(vim.fn.getcwd())
  local cwd = vim.fn.getcwd()

  local transform_path = function(path)
    local cwd_or_bare = cwd
    if is_bare then
      cwd_or_bare = bare_path
    end

    if path:sub(1, #cwd_or_bare) == cwd_or_bare then
      return path:sub(#cwd_or_bare + 2)
    end

    return path
  end

  local parse_line = function(line)
    local fields = vim.split(string.gsub(line, '%s+', ' '), ' ')
    local session = session_map[fields[1]] or { session_name = '' }
    local entry = {
      session = session.session_name,
      path = fields[1],
      sha = fields[2],
      branch = fields[3],
    }

    if entry.sha ~= '(bare)' and entry.path ~= cwd then
      for key, val in pairs(widths) do
        if key == 'path' then
          local new_path = transform_path(entry[key])
          local path_len = strings.strdisplaywidth(new_path or '')
          widths[key] = math.max(val, path_len)
        else
          widths[key] = math.max(val, strings.strdisplaywidth(entry[key] or ''))
        end
      end

      if entry.session:len() > 0 then
        results_with_session[#results_with_session + 1] = entry
      else
        results[#results + 1] = entry
      end
    end
  end

  for _, line in ipairs(output) do
    parse_line(line)
  end

  for _, entry in ipairs(results_with_session) do
    table.insert(results, 1, entry)
  end

  if #results == 0 then
    print('No worktrees found')
    return
  end

  local displayer = require('telescope.pickers.entry_display').create({
    separator = ' ',
    items = {
      { width = widths.session },
      { width = widths.branch },
      { width = widths.path },
      { width = widths.sha },
    },
  })

  local make_display = function(entry)
    return displayer({
      { entry.session, 'TelescopeResultsIdentifier' },
      { entry.branch, 'TelescopeResultsIdentifier' },
      { transform_path(entry.path) },
      { entry.sha },
    })
  end

  local finder = finders.new_table({
    results = results,
    entry_maker = function(entry)
      entry.value = entry.branch:gsub('^%[(.*)%]$', '%1')
      entry.ordinal = entry.session .. ' ' .. entry.branch
      entry.display = make_display
      return entry
    end,
  })

  pickers
    .new(opts or {}, {
      prompt_title = 'Git Worktrees',
      previewer = previewers.git_branch_log.new(opts),
      finder = finder,
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(bufnr, map)
        action_set.select:replace(switch_worktree)

        map('i', '<c-x>', close_session(finder))
        map('n', '<c-x>', close_session(finder))

        return true
      end,
    })
    :find()
end

return require('telescope').register_extension({
  exports = {
    git_worktrees = telescope_git_worktree,
    create_git_worktree = create_worktree,
  },
})
