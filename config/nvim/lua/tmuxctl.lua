local M = {}
local git = {}

function git.is_bare(path)
  path = path or vim.fn.getcwd()
  local fwt = vim.split(vim.fn.system('cd ' .. vim.fn.fnameescape(path) .. ' && git worktree list'), '\n')[1]

  if fwt:sub(#fwt - 5) == '(bare)' then
    return true, fwt:gsub('%(bare%)$', ''):gsub('[ ]*$', '')
  else
    return false, nil
  end
end

function M.name_session(path)
  return vim.fn.system('tmux-session-name ' .. vim.fn.fnameescape(path)):gsub('\n', '')
end

function M.rename_session(session_name)
  return os.execute('tmux rename-session ' .. vim.fn.fnameescape(session_name))
end

function M.create_session(session_name, opts)
  opts.cmd = opts.cmd or ''
  opts.path = opts.path or ''
  local cmd = 'tmux new-session -d -s ' .. vim.fn.shellescape(session_name)
  if opts.path:len() > 0 then
    cmd = cmd .. ' -c ' .. vim.fn.fnameescape(opts.path)
  end
  if opts.cmd:len() > 0 then
    cmd = cmd .. ' ' .. opts.cmd
  end

  return os.execute(cmd)
end

function M.send(session_name, command)
  return os.execute('tmux send -t ' .. vim.fn.fnameescape(session_name) .. ':0.0 ' .. command)
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

function M.switch_to_path(path)
  local tmux = M

  local is_bare, bare_path = git.is_bare(path)

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
    if switched and not has_buffers() then
      vim.cmd.quit()
    end
  end
end

return M
