local M = {}

function M.is_bare(path)
  path = path or vim.fn.getcwd()
  local fwt = vim.split(vim.fn.system('cd ' .. vim.fn.fnameescape(path) .. ' && git worktree list'), '\n')[1]

  if fwt:sub(#fwt - 5) == '(bare)' then
    return true, fwt:gsub('%(bare%)$', ''):gsub('[ ]*$', '')
  else
    return false, nil
  end
end

local function tmux(cmd)
  -- vim.notify(cmd, vim.log.levels.INFO, { title = 'tmuxctl' })
  return vim.fn.system('tmux ' .. cmd)
end

function M.name_session(path)
  return vim.fn.system('tmux-session-name ' .. vim.fn.shellescape(path)):gsub('\n', '')
end

function M.move_pane_to_project()
  local path = vim.fn.getcwd()
  local session_name = M.name_session(path)
  print(session_name)
  if not M.has_session(session_name) then
    print('create ' .. session_name)
    M.create_session(session_name, { path = path })
  end
  print('tmux break-pane -t ' .. vim.fn.shellescape(session_name) .. ' -s ' .. os.getenv('TMUX_PANE'))
  M.switch_session(session_name)
  tmux('break-pane -t ' .. vim.fn.shellescape(session_name) .. ' -s ' .. os.getenv('TMUX_PANE'))
end

function M.rename_session(session_name)
  return os.execute('tmux rename-session ' .. vim.fn.shellescape(session_name))
end

function M.create_session(session_name, opts)
  opts.cmd = opts.cmd or ''
  opts.path = opts.path or ''
  local cmd = 'tmux new-session -d -s ' .. vim.fn.shellescape(session_name)
  if opts.path:len() > 0 then
    cmd = cmd .. ' -c ' .. vim.fn.shellescape(opts.path)
  end
  if opts.cmd:len() > 0 then
    cmd = cmd .. ' ' .. opts.cmd
  end

  return os.execute(cmd)
end

function M.send(session_name, command)
  return os.execute('tmux send -t ' .. vim.fn.shellescape(session_name) .. ':0.0 ' .. command)
end

function M.has_session(session_name)
  local has_session = os.execute('tmux has-session -t ' .. vim.fn.shellescape(session_name) .. ' >/dev/null 2>&1')
  return has_session == 0
end

function M.current_session_name()
  local name = vim.fn.system('tmux display-message -p "#S" 2>/dev/null'):gsub('\n$', '')
  return name
end

function M.switch_session(session_name)
  if M.has_session(session_name) then
    if os.getenv('TMUX') then
      os.execute('tmux switch-client -t ' .. vim.fn.shellescape(session_name) .. ' >/dev/null 2>&1')
    else
      vim.fn.jobstart(
        'alacritty -e bash -ic "tmux attach -t ' .. vim.fn.shellescape(session_name) .. '"',
        { detach = true }
      )
    end
    return true
  end

  return false
end

function M.get_path_session_name_map()
  local result = {}
  local lines = vim.split(vim.fn.system('tmux list-sessions -F "#{session_name} #{session_path}"'), '\n')
  for _, line in pairs(lines) do
    if line ~= '' then
      local fields = vim.split(line:gsub('%s+', ' '), ' ')
      result[fields[2]] = { path = fields[2], session_name = fields[1] }
    end
  end

  return result
end

local function has_buffers()
  local bufs = vim.api.nvim_list_bufs()
  for _, bufnr in pairs(bufs) do
    local blisted = vim.api.nvim_buf_get_option(bufnr, 'buflisted')
    local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
    local modified = vim.api.nvim_buf_get_option(bufnr, 'modified')
    if blisted then
      if modified then
        return true
      end

      if filetype ~= '' then
        return true
      end
    end
  end

  return false
end

function M.close_session(session_name)
  if session_name:len() > 0 then
    vim.fn.system('tmux kill-session -t ' .. vim.fn.shellescape(session_name))
  end
end

function M.switch_to_path(path)
  local tmux = M

  local is_bare, bare_path = M.is_bare(path)

  local session_name = tmux.name_session(path)
  local current_name = tmux.current_session_name()

  if not tmux.has_session(session_name) then
    tmux.create_session(session_name, {
      cmd = 'nvim',
      path = path,
    })
  end

  if current_name ~= session_name then
    local switched = tmux.switch_session(session_name)

    if is_bare then
      vim.fn.writefile({ path }, bare_path .. '/current_worktree')
    end

    -- update mod time on the project, will make it appear first on the list
    if switched then
      os.execute('[[ -d ' .. path .. '/.git || -f ' .. path .. '/.git ]] && touch ' .. path .. '/.git')
    end
    -- if current session seams empty jsut close it
  end
end

local pane_names = {}
local last_pane = nil

local function in_table(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end

function M.list_named_panes()
  dump(pane_names)
end

function M.get_last_pane()
  return last_pane
end

function M.set_last_pane(name)
  last_pane = name
end

function M.get_pane_id(name)
  return pane_names[name]
end

---check if named pane exists
---@param name string - name of the pane
function M.pane_exists(name)
  local id = pane_names[name]
  if not id then
    return false
  end
  id = id:sub(2)

  local all = tmux('list-panes -F "#{pane_id}" -a')
  return all:find('%%' .. id .. '\n') ~= nil
end

local function def_opts(opts, override)
  opts = vim.tbl_extend('keep', opts or {}, {
    height = 15,
    focus = true,
    create_cmd = nil,
    cmd = true,
    open = true,
    dir = vim.fn.getcwd(),
  })
  return vim.tbl_extend('keep', override or {}, opts)
end

local function opts_to_tmux_str(opts, keys)
  opts = def_opts(opts)
  local commands = {}
  if keys.height then
    commands[#commands + 1] = 'resize-pane -y ' .. opts.height
  end
  if not opts.focus and keys.focus then
    commands[#commands + 1] = 'select-pane -t ' .. os.getenv('TMUX_PANE')
  end
  local result = ''
  if #commands > 0 then
    result = ' \\; ' .. vim.fn.join(commands, ' \\; ')
  end
  return result
end

---create a new pane with a given name
---@param name string - name of the pane
---@param opts table|nil - options { height, create_cmd }
function M.create_pane(name, opts)
  opts = def_opts(opts)
  local ids = vim.fn.split(vim.fn.system('tmux list-panes -F "#{pane_id}"'), '\n')
  if pane_names[name] and in_table(ids, pane_names[name]) then
    return true
  end
  local cmd = ''
  if opts.create_cmd then
    cmd = vim.fn.shellescape(opts.create_cmd)
  end
  local id = tmux(
    'split-window -v -P -F "#{pane_id}" -c '
      .. vim.fn.shellescape(opts.dir)
      .. ' '
      .. cmd
      .. opts_to_tmux_str(opts, { height = true, focus = true })
  ):gsub('\n', '')
  pane_names[name] = id

  if opts.create_cmd then
    M.send_to_pane(name, opts.create_cmd)
  end
end

---send a command to a pane, if named pane does not exist it will be created
---@param name string - name of the pane
---@param cmd string - command to send
---@param opts table|nil - options { cmd, open, height, create_cmd }
function M.send_to_pane(name, cmd, opts)
  opts = def_opts(opts)
  M.set_last_pane(name)

  if not M.pane_exists(name) then
    M.create_pane(name, opts)
  end

  if opts.open then
    M.show_pane(name)
  end
  if opts.cmd then
    -- clear pane prompt
    M.send_to_pane(
      name,
      'c-c c-e c-u c-l',
      def_opts(opts, {
        cmd = false,
        open = false,
      })
    )
    cmd = vim.fn.shellescape(cmd) .. ' Enter'
  end

  tmux('send-keys -t ' .. pane_names[name] .. ' ' .. cmd .. opts_to_tmux_str(opts, {
    focus = true,
  }))
end

function M.toggle_pane(name, opts)
  if M.is_pane_opend(name) then
    M.hide_pane(name)
  else
    M.show_pane(name, opts)
  end
end

function M.focus_nvim_pane()
  tmux('select-pane -t ' .. os.getenv('TMUX_PANE'))
end

function M.show_pane(name, opts)
  opts = vim.tbl_extend('keep', opts or {}, { height = 15, focus = true })
  if not M.pane_exists(name) then
    M.create_pane(name, opts)
  else
    tmux('join-pane -s ' .. pane_names[name] .. opts_to_tmux_str(opts, { height = true, focus = true }))
  end
end

function M.hide_all_panes()
  tmux('new-session -d -s _hidden')
  local ids = vim.fn.split(vim.fn.system('tmux list-panes -F "#{pane_id}"'), '\n')
  for _, id in ipairs(ids) do
    if id ~= os.getenv('TMUX_PANE') then
      tmux('break-pane -t _hidden -s ' .. id)
    end
  end
end

function M.hide_pane(name)
  if not M.pane_exists(name) then
    return
  end
  tmux('new-session -d -s _hidden')
  tmux('break-pane -t _hidden -s ' .. M.get_pane_id(name))
end

function M.is_pane_opend(name)
  local ids = vim.fn.split(vim.fn.system('tmux list-panes -F "#{pane_id}"'), '\n')
  return pane_names[name] and in_table(ids, pane_names[name])
end

local augroup = vim.api.nvim_create_augroup('tmuxctl', { clear = true })
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = augroup,
  pattern = '*',
  callback = function()
    for name, id in pairs(pane_names) do
      tmux('kill-pane -t ' .. id)
      pane_names[name] = nil
    end
  end,
})

return M
