local api, fn, uv = vim.api, vim.fn, vim.uv
local ns = api.nvim_create_namespace('agent-review')
local directory = fn.stdpath('state') .. '/agent-review'
local states, sending = {}, {}
local defaults = {
  review_begin = 'Review feedback:',
  review_end = '',
  review_approve = 'Approved. No issues found.',
  filter_herdr_app = false,
}
local config = defaults

local function worktree(path)
  local root = vim.fs.root(path, '.git')
  if root then return uv.fs_realpath(root), vim.fs.relpath(root, path) end
end

local function current_root()
  local root = worktree(api.nvim_buf_get_name(0)) or worktree(fn.getcwd())
  assert(root, 'Review needs a Git worktree')
  return root
end

local function filename(root) return directory .. '/' .. fn.sha256(root) .. '.json' end

local function state(root)
  if not states[root] then
    local path = filename(root)
    local stat, err, code = uv.fs_stat(path)
    local data = { root = root, draft = {}, history = {} }
    if stat then
      data = vim.json.decode(table.concat(fn.readfile(path), '\n'))
      assert(data.root == root and vim.islist(data.draft) and vim.islist(data.history), 'Invalid review file: ' .. path)
    else
      assert(code == 'ENOENT', err)
    end
    states[root] = data
  end
  return states[root]
end

-- Match the quoted code again after a reload, preferring the original position.
local function anchor(lines, c)
  local function matches(row)
    for i, line in ipairs(c.code) do
      if lines[row + i - 1] ~= line then return false end
    end
    return true
  end
  if matches(c.first) then return c.first end
  local found
  for row = 1, #lines do
    if matches(row) then
      if found then return end -- ambiguous; don't mark unrelated code
      found = row
    end
  end
  return found
end

local function draw(buf, root, path)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines
  for idx, c in ipairs(state(root).draft) do
    if c.path and c.path == path then
      lines = lines or api.nvim_buf_get_lines(buf, 0, -1, false)
      local row = anchor(lines, c)
      if row then
        api.nvim_buf_set_extmark(buf, ns, row - 1, 0, {
          sign_text = '●',
          sign_hl_group = 'DiagnosticHint',
          id = idx,
        })
      end
    end
  end
end

local function update(root, change)
  local next_state = vim.deepcopy(state(root))
  change(next_state)
  local json = vim.json.encode(next_state)
  fn.mkdir(directory, 'p', 448)
  local fd, tmp = uv.fs_mkstemp(filename(root) .. '.XXXXXX')
  assert(fd, tmp)
  uv.fs_close(fd)
  local ok, err = pcall(function()
    assert(fn.writefile({ json }, tmp, 's') == 0, 'Could not save review')
    assert(uv.fs_rename(tmp, filename(root)))
  end)
  if not ok then
    uv.fs_unlink(tmp)
    error(err)
  end
  states[root] = next_state
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
      local other, path = worktree(api.nvim_buf_get_name(buf))
      if other == root then draw(buf, root, path) end
    end
  end
end

local group = api.nvim_create_augroup('AgentReview', { clear = true })
api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  group = group,
  callback = function(ev)
    local root, path = worktree(api.nvim_buf_get_name(ev.buf))
    if root and path then draw(ev.buf, root, path) end
  end,
})

local function edit_text(source, first, last, text, save, title)
  local lines = vim.split(text, '\n', { plain = true })
  local wanted = math.max(4, math.min(10, #lines))
  local layout
  if first then
    local top = api.nvim_win_get_position(source)[1]
    local height = api.nvim_win_get_height(source)
    local above = math.max(0, fn.screenpos(source, first, 1).row - top - 1)
    local bottom = fn.screenpos(source, last, math.max(1, fn.col({ last, '$' }) - 1)).row
    local below = bottom == 0 and 0 or math.max(0, top + height - bottom)
    local up = below < wanted + 2 and above > below
    layout = {
      relative = 'win',
      win = source,
      row = up and above or height - below,
      col = 0,
      anchor = up and 'SW' or 'NW',
      width = math.max(1, math.min(72, api.nvim_win_get_width(source) - 2)),
      height = math.max(1, math.min(wanted, (up and above or below) - 2)),
    }
  else
    local width = math.max(1, math.min(72, vim.o.columns - 2))
    local rows = vim.o.lines - vim.o.cmdheight
    local height = math.max(1, math.min(wanted, rows - 2))
    layout = {
      relative = 'editor',
      width = width,
      height = height,
      row = math.floor((rows - height - 2) / 2),
      col = math.floor((vim.o.columns - width - 2) / 2),
    }
  end
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].bufhidden = 'wipe'
  api.nvim_buf_set_name(buf, 'agent-review://comment/' .. buf)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
  local win = api.nvim_open_win(
    buf,
    true,
    vim.tbl_extend('force', layout, {
      style = 'minimal',
      border = 'rounded',
      title = title or ' Review comment ',
      footer = ' :w / Ctrl-S save · q cancel ',
    })
  )
  vim.wo[win].wrap = true
  local function close()
    vim.cmd.stopinsert()
    api.nvim_win_close(win, true)
  end
  local function submit()
    save(table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), '\n'))
    vim.bo[buf].modified = false
    close()
  end
  api.nvim_create_autocmd('BufWriteCmd', { buffer = buf, callback = submit })
  vim.keymap.set({ 'i', 'n' }, '<C-s>', submit, { buffer = buf })
  vim.keymap.set('n', 'q', close, { buffer = buf })
  api.nvim_win_set_cursor(win, { #lines, #lines[#lines] })
  vim.cmd.startinsert({ bang = true })
end

local function new_id() return fn.sha256(fn.getpid() .. ':' .. tostring(uv.hrtime())) end

local function comment(opts)
  local source = api.nvim_get_current_win()
  local file = api.nvim_buf_get_name(0)
  local root, path = worktree(file)
  assert(root and path and vim.bo.buftype == '', 'Review needs a file in a Git worktree')
  local first, last = opts.line1, opts.line2
  local code = api.nvim_buf_get_lines(0, first - 1, last, false)
  local matches = {}
  for _, mark in ipairs(api.nvim_buf_get_extmarks(0, ns, { first - 1, 0 }, { first - 1, -1 }, {})) do
    table.insert(matches, state(root).draft[mark[1]])
  end
  local function edit(old)
    edit_text(source, first, last, old and old.text or '', function(text)
      if not old and vim.trim(text) == '' then return end
      update(root, function(s)
        if old then
          for i, c in ipairs(s.draft) do
            if c.id == old.id then
              if vim.trim(text) == '' then
                table.remove(s.draft, i)
              else
                c.text = text
              end
              return
            end
          end
          error('This comment is no longer in the draft')
        end
        table.insert(s.draft, {
          id = new_id(),
          path = path,
          first = first,
          last = last,
          code = code,
          text = text,
        })
      end)
    end)
  end
  if #matches < 2 then return edit(matches[1]) end
  vim.ui.select(
    matches,
    { prompt = 'Edit comment', format_item = function(c) return c.text:match('^[^\n]*') end },
    function(c)
      if c then edit(c) end
    end
  )
end

local function message(comments)
  local parts = {}
  local function add(text)
    if vim.trim(text) ~= '' then table.insert(parts, text) end
  end
  add(config.review_begin)
  for _, c in ipairs(comments) do
    if not c.path then add(c.text) end
  end
  for _, c in ipairs(comments) do
    if c.path then
      local code = c.code
      if #code > 3 then code = { code[1], '...', code[#code] } end
      add(('%s:%d-%d\n    %s\n\n%s'):format(c.path, c.first, c.last, table.concat(code, '\n    '), c.text))
    end
  end
  add(config.review_end)
  return table.concat(parts, '\n\n')
end

local function archive(s, kind, comments, text, session)
  table.insert(s.history, 1, {
    kind = kind,
    time = os.time(),
    comments = vim.deepcopy(comments),
    message = text or message(comments),
    session = session and { id = session.id, title = session.title },
  })
end

local function pick_batch(root, prompt, action)
  local history = state(root).history
  if #history == 0 then return vim.notify('No archived reviews for this worktree') end
  vim.ui.select(history, {
    prompt = prompt,
    format_item = function(b)
      return ('%s  %s  %s  [%d] %s'):format(
        os.date('%F %T', b.time),
        b.kind,
        b.session and (b.session.title or b.session.id) or '',
        #b.comments,
        b.comments[1] and b.comments[1].text:match('^[^\n]*') or ''
      )
    end,
  }, function(b)
    if b then action(b) end
  end)
end

local function restore(opts)
  local root = current_root()
  pick_batch(root, opts.bang and 'Merge archived review' or 'Restore archived review', function(batch)
    update(root, function(s)
      if opts.bang or #s.draft > 0 then archive(s, opts.bang and 'before merge' or 'unsent', s.draft) end
      if not opts.bang then s.draft = {} end
      local ids = {}
      for _, c in ipairs(s.draft) do
        ids[c.id] = true
      end
      for _, c in ipairs(batch.comments) do
        if not ids[c.id] then table.insert(s.draft, vim.deepcopy(c)) end
      end
    end)
  end)
end

api.nvim_create_user_command('ReviewComment', comment, { range = true })
api.nvim_create_user_command('ReviewRestore', restore, { bang = true })

local function read_json(cmd, opts, done)
  local ok, err = pcall(
    vim.system,
    cmd,
    opts,
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then return done(nil, vim.trim(result.stderr ~= '' and result.stderr or result.stdout)) end
      local parsed, response = pcall(vim.json.decode, result.stdout)
      if not parsed or type(response) ~= 'table' then return done(nil, 'Invalid response from ' .. cmd[1]) end
      done(response)
    end)
  )
  if not ok then done(nil, tostring(err)) end
end

local function request(root, args, done)
  read_json(vim.list_extend({ 'opencode', 'api' }, args), { cwd = root, text = true }, done)
end

local function report(err) vim.notify('Review: ' .. err, vim.log.levels.ERROR) end

local function in_worktree(path, root) return type(path) == 'string' and path ~= '' and worktree(path) == root end

local function herdr_tabs(root, done)
  if not config.filter_herdr_app then return done({}) end
  read_json({ 'herdr-app', 'ls' }, { text = true, timeout = 2000 }, function(layout)
    local live = {}
    for _, space in ipairs(layout and layout.spaces or {}) do
      if in_worktree(space.folder, root) then
        for _, tab in ipairs(space.tabs or {}) do
          local role = tab.name == 'opencode' and 'oc-1' or tab.name
          if type(role) == 'string' and role:match('^oc%-%d+$') then
            for _, term in ipairs(tab.terminals or {}) do
              if term.app == 'opencode' then live[term.terminal] = { key = space.id .. '/' .. role, role = role } end
            end
          end
        end
      end
    end
    if not next(live) then return done({}) end
    local rpc = '{"jsonrpc":"2.0","id":1,"method":"doc.get","params":{"name":"pbogut-opencode"}}\n'
    read_json({ 'hc', 'connect' }, { text = true, stdin = rpc, timeout = 2000 }, function(doc)
      local slots = vim.tbl_get(doc or {}, 'result', 'value', 'slots') or {}
      local tabs = {}
      for terminal, tab in pairs(live) do
        local slot = slots[tab.key]
        if slot and slot.terminal == terminal and type(slot.sessionID) == 'string' then
          tabs[slot.sessionID] = tab.role
        end
      end
      done(tabs)
    end)
  end)
end

local function pick_session(root, label, action)
  local last
  for _, b in ipairs(state(root).history) do
    if b.session then
      last = b.session.id
      break
    end
  end
  local sessions = {}
  local function show(tabs)
    local open = vim.tbl_filter(function(s) return tabs[s.id] ~= nil end, sessions)
    local choices = #open > 0 and open or sessions
    for i, s in ipairs(choices) do
      if s.id == last then
        table.insert(choices, 1, table.remove(choices, i))
        break
      end
    end
    vim.ui.select(choices, {
      prompt = label,
      format_item = function(s)
        return (s.id == last and '[Last review] ' or '')
          .. (tabs[s.id] and tabs[s.id] .. ' · ' or '')
          .. (s.title or 'Untitled')
          .. '  '
          .. s.id
      end,
    }, function(s)
      if s then action(s) end
    end)
  end
  local function page(cursor)
    local args = {
      'session.list',
      '--param',
      'directory=' .. root,
      '--param',
      'parentID=null',
      '--param',
      'archived=false',
      '--param',
      'limit=100',
    }
    if cursor then vim.list_extend(args, { '--param', 'cursor=' .. cursor }) end
    request(root, args, function(result, err)
      if not (result and vim.islist(result.data)) then return report(err or 'Could not list sessions') end
      for _, s in ipairs(result.data) do
        if in_worktree(s.location and s.location.directory, root) then table.insert(sessions, s) end
      end
      local next_page = result.cursor and result.cursor.next
      if type(next_page) == 'string' then return page(next_page) end
      if #sessions == 0 then return vim.notify('No OpenCode conversations in ' .. root) end
      herdr_tabs(root, show)
    end)
  end
  page()
end

local function send(root, batch, approve_if_empty)
  if sending[root] then return vim.notify('A review is being sent') end
  local comments = batch and batch.comments or state(root).draft
  local approval = #comments == 0 and (approve_if_empty or (batch and batch.kind == 'approved'))
  if #comments == 0 and not approval then return vim.notify('No comments to send') end
  local text = batch and batch.message or (approval and config.review_approve or message(comments))
  local label = approval and 'Approve review' or 'Send feedback'
  pick_session(root, label, function(session)
    if sending[root] then return vim.notify('A review is being sent') end
    if not batch and not vim.deep_equal(state(root).draft, comments) then
      return vim.notify('Draft changed. Open the review picker again.')
    end
    sending[root] = true
    request(
      root,
      { 'session.prompt', '--param', 'sessionID=' .. session.id, '--data', vim.json.encode({ text = text }) },
      function(result, err)
        sending[root] = nil
        if not (result and result.data and result.data.sessionID == session.id) then
          return report(err or 'OpenCode did not confirm delivery')
        end
        update(root, function(s)
          archive(s, approval and 'approved' or (batch and 'resent' or 'sent'), comments, text, session)
          if not batch then
            -- Keep comments added or edited while the request was in flight.
            local sent = {}
            for _, c in ipairs(comments) do
              sent[c.id] = c
            end
            s.draft = vim.tbl_filter(function(c) return not vim.deep_equal(c, sent[c.id]) end, s.draft)
          end
        end)
        vim.notify('Review sent to ' .. (session.title or session.id))
      end
    )
  end)
end

api.nvim_create_user_command('ReviewSend', function() send(current_root(), nil, true) end, {})
api.nvim_create_user_command('ReviewSendWithComment', function()
  local root = current_root()
  local general = vim.tbl_filter(function(c) return not c.path end, state(root).draft)
  local previous = table.concat(vim.tbl_map(function(c) return c.text end, general), '\n\n')
  edit_text(nil, nil, nil, previous, function(text)
    if text ~= previous then
      update(root, function(s)
        s.draft = vim.tbl_filter(function(c) return c.path ~= nil end, s.draft)
        if vim.trim(text) ~= '' then
          table.insert(s.draft, { id = general[1] and general[1].id or new_id(), text = text })
        end
      end)
    end
    send(root)
  end, ' General review comment ')
end, {})
api.nvim_create_user_command('ReviewResend', function()
  local root = current_root()
  pick_batch(root, 'Resend archived review', function(batch) send(root, batch) end)
end, {})

return {
  setup = function(opts) config = vim.tbl_extend('force', defaults, opts or {}) end,
}
