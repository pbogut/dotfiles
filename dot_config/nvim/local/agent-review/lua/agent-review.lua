local api, fn, uv = vim.api, vim.fn, vim.uv
local ns = api.nvim_create_namespace('agent-review')
local directory = fn.stdpath('state') .. '/agent-review'
local states, sending = {}, {}
local defaults = {
  -- approval_mode, feedback_mode and send_mode are optional OpenCode agent IDs.
  review_begin = 'Review feedback:',
  review_end = '',
  send_begin = '',
  send_end = '',
  review_approve = 'Approved. No issues found.',
  filter_herdr_app = false,
}
local config = defaults

-- Catch errors where Neovim enters the plugin, including callbacks that run later.
local function guarded(callback, fallback)
  return function(...)
    local ok, value = pcall(callback, ...)
    if ok then return value end
    local message = tostring(value):gsub('^.-%.lua:%d+: ', '')
    vim.notify(message, vim.log.levels.ERROR)
    return fallback
  end
end

local function select_item(items, opts, on_choice)
  opts.format_item = guarded(opts.format_item, '[Invalid review entry]')
  vim.ui.select(items, opts, guarded(on_choice))
end

local function command(name, callback, opts) api.nvim_create_user_command(name, guarded(callback), opts or {}) end

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
      local contents = fn.readfile(path)
      local ok, parsed = pcall(vim.json.decode, table.concat(contents, '\n'))
      assert(
        ok
          and type(parsed) == 'table'
          and parsed.root == root
          and vim.islist(parsed.draft)
          and vim.islist(parsed.history),
        'Invalid review file: ' .. path
      )
      data = parsed
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
    error(err, 0)
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
  callback = guarded(function(ev)
    local root, path = worktree(api.nvim_buf_get_name(ev.buf))
    if root and path then draw(ev.buf, root, path) end
  end),
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
  local save_comment = guarded(submit)
  api.nvim_create_autocmd('BufWriteCmd', { buffer = buf, callback = save_comment })
  vim.keymap.set({ 'i', 'n' }, '<C-s>', save_comment, { buffer = buf })
  vim.keymap.set('n', 'q', guarded(close), { buffer = buf })
  api.nvim_win_set_cursor(win, { #lines, #lines[#lines] })
  vim.cmd.startinsert({ bang = true })
end

local function new_id() return fn.sha256(fn.getpid() .. ':' .. tostring(uv.hrtime())) end

local function comment(opts)
  local source = api.nvim_get_current_win()
  local file = api.nvim_buf_get_name(0)
  local root, path = worktree(file)
  if not root or not path or vim.bo.buftype ~= '' then
    return vim.notify('Review needs a file in a Git worktree', vim.log.levels.INFO)
  end
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
  select_item(
    matches,
    { prompt = 'Edit comment', format_item = function(c) return c.text:match('^[^\n]*') end },
    function(c)
      if c then edit(c) end
    end
  )
end

local function message(comments, kind)
  local parts = {}
  local function add(text)
    if vim.trim(text) ~= '' then table.insert(parts, text) end
  end
  add(kind == 'message' and config.send_begin or config.review_begin)
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
  add(kind == 'message' and config.send_end or config.review_end)
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
  select_item(history, {
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

command('ReviewComment', comment, { range = true })
command('ReviewRestore', restore, { bang = true })

local function run(cmd, opts, done)
  local ok, err = pcall(
    vim.system,
    cmd,
    opts,
    vim.schedule_wrap(guarded(function(result)
      if result.code ~= 0 then
        return done(nil, vim.trim(result.stderr ~= '' and result.stderr or result.stdout or ''))
      end
      done(result.stdout or '')
    end))
  )
  if not ok then done(nil, tostring(err)) end
end

local function read_json(cmd, opts, done)
  run(cmd, opts, function(stdout, err)
    if err then return done(nil, err) end
    local parsed, response = pcall(vim.json.decode, stdout)
    if not parsed or type(response) ~= 'table' then return done(nil, 'Invalid response from ' .. cmd[1]) end
    done(response)
  end)
end

local function request(root, args, done)
  -- switchAgent returns HTTP 204; its exit status is the acknowledgement.
  local execute = args[1] == 'session.switchAgent' and run or read_json
  execute(vim.list_extend({ 'opencode', 'api' }, args), { cwd = root, text = true }, done)
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

local function preview_reply(root, id, buf, cursor)
  local args =
    { 'session.message.list', '--param', 'sessionID=' .. id, '--param', 'type=assistant', '--param', 'limit=5' }
  vim.list_extend(args, { '--param', cursor and 'cursor=' .. cursor or 'order=desc' })
  request(root, args, function(result, err)
    -- Each session owns its preview buffer, even when replies arrive out of order.
    if not api.nvim_buf_is_loaded(buf) then return end
    local function show(text) api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, '\n', { plain = true })) end
    if not (result and vim.islist(result.data)) then
      return show('Could not load reply' .. (err and err ~= '' and ': ' .. err or '.'))
    end
    for _, msg in ipairs(result.data) do
      local parts = {}
      for _, part in ipairs(msg.content or {}) do
        if part.type == 'text' then table.insert(parts, part.text) end
      end
      local text = table.concat(parts, '\n\n')
      if vim.trim(text) ~= '' then
        show(text)
        vim.bo[buf].filetype = 'markdown'
        require('telescope.previewers.utils').highlighter(buf, 'markdown')
        return
      end
    end
    local next_page = result.cursor and result.cursor.next
    if type(next_page) == 'string' then return preview_reply(root, id, buf, next_page) end
    show('No assistant reply yet.')
  end)
end

local function open_session_picker(root, label, action)
  local ok, pickers = pcall(require, 'telescope.pickers')
  if not ok then return end
  local actions = require('telescope.actions')
  local picker
  picker = pickers.new({}, {
    prompt_title = label,
    results_title = 'Loading sessions...',
    layout_strategy = 'vertical',
    layout_config = { mirror = true, preview_cutoff = 1 },
    cache_picker = false,
    finder = require('telescope.finders').new_table({ results = {} }),
    sorter = require('telescope.config').values.generic_sorter({}),
    previewer = require('telescope.previewers').new_buffer_previewer({
      title = 'Last assistant reply',
      get_buffer_by_name = function(_, entry) return entry.value.id end,
      define_preview = function(self, entry)
        if self.state.bufname == entry.value.id then return end
        local buf = self.state.bufnr
        vim.wo[self.state.winid].wrap = true
        vim.wo[self.state.winid].linebreak = true
        api.nvim_buf_set_lines(buf, 0, -1, false, { 'Loading reply...' })
        preview_reply(root, entry.value.id, buf)
      end,
    }),
    attach_mappings = function(prompt_buf, map)
      actions.select_default:replace(guarded(function()
        local entry = picker:get_selection()
        if not entry then return end
        actions.close(prompt_buf)
        action(entry.value)
      end))
      map({ 'i', 'n' }, '<Esc>', actions.close)
      return true
    end,
  })
  picker:find()
  return picker
end

local function pick_session(root, label, action)
  local last
  for _, b in ipairs(state(root).history) do
    if b.session then
      last = b.session.id
      break
    end
  end
  local picker = open_session_picker(root, label, action)
  local sessions, tabs, listed = {}, nil, false
  local function active() return not picker or api.nvim_buf_is_loaded(picker.prompt_bufnr) end
  local function show()
    if not (listed and tabs and active()) then return end
    local open = vim.tbl_filter(function(s) return tabs[s.id] ~= nil end, sessions)
    local choices = #open > 0 and open or sessions
    for i, s in ipairs(choices) do
      if s.id == last then
        table.insert(choices, 1, table.remove(choices, i))
        break
      end
    end
    local function format_item(s)
      return (s.id == last and '* ' or '  ')
        .. (tabs[s.id] and tabs[s.id] .. ' · ' or '')
        .. (s.title or 'Untitled')
        .. '  '
        .. s.id
    end
    if not picker then
      return select_item(choices, { prompt = label, format_item = format_item }, function(s)
        if s then action(s) end
      end)
    end
    picker.results_title = 'Sessions'
    local border = picker.layout.results.border
    if border then border:change_title(picker.results_title) end
    picker:refresh(require('telescope.finders').new_table({
      results = choices,
      entry_maker = function(s)
        local display = format_item(s)
        return { value = s, display = display, ordinal = display }
      end,
    }))
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
      if not active() then return end
      if not (result and vim.islist(result.data)) then
        if picker then require('telescope.actions').close(picker.prompt_bufnr) end
        return report(err or 'Could not list sessions')
      end
      for _, s in ipairs(result.data) do
        if in_worktree(s.location and s.location.directory, root) then table.insert(sessions, s) end
      end
      local next_page = result.cursor and result.cursor.next
      if type(next_page) == 'string' then return page(next_page) end
      if #sessions == 0 then
        if picker then require('telescope.actions').close(picker.prompt_bufnr) end
        return vim.notify('No OpenCode conversations in ' .. root)
      end
      listed = true
      show()
    end)
  end
  page()
  herdr_tabs(root, function(result)
    tabs = result
    show()
  end)
end

local function prompt_session(root, id, text, mode, done)
  local session = 'sessionID=' .. id
  local function prompt()
    request(root, { 'session.prompt', '--param', session, '--data', vim.json.encode({ text = text }) }, done)
  end
  if not mode then return prompt() end
  local args = { 'session.switchAgent', '--param', session, '--data', vim.json.encode({ agent = mode }) }
  request(root, args, function(_, err)
    if err then return done(nil, 'Could not switch to ' .. mode .. (err ~= '' and ': ' .. err or '')) end
    prompt()
  end)
end

local function send(root, kind, batch)
  if sending[root] then return vim.notify('Already sending to OpenCode') end
  local comments = batch and batch.comments or state(root).draft
  local approval = #comments == 0 and (kind == 'review' or kind == 'approved')
  if #comments == 0 and not approval then return vim.notify('No comments to send') end
  local text = batch and batch.message or (approval and config.review_approve or message(comments, kind))
  local label = kind == 'message' and 'Send message' or (approval and 'Approve review' or 'Send feedback')
  local mode = config[kind == 'message' and 'send_mode' or (approval and 'approval_mode' or 'feedback_mode')]
  pick_session(root, label, function(session)
    if sending[root] then return vim.notify('Already sending to OpenCode') end
    if not batch and not vim.deep_equal(state(root).draft, comments) then
      return vim.notify('Draft changed. Choose a recipient again.')
    end
    sending[root] = true
    prompt_session(root, session.id, text, mode, function(result, err)
      sending[root] = nil
      if not (result and result.data and result.data.sessionID == session.id) then
        return report(err or 'OpenCode did not confirm delivery')
      end
      update(root, function(s)
        local archived_kind = approval and 'approved' or (kind == 'message' and 'message') or (batch and 'resent' or 'sent')
        archive(s, archived_kind, comments, text, session)
        if not batch then
          -- Keep comments added or edited while the request was in flight.
          local sent = {}
          for _, c in ipairs(comments) do
            sent[c.id] = c
          end
          s.draft = vim.tbl_filter(function(c) return not vim.deep_equal(c, sent[c.id]) end, s.draft)
        end
      end)
      vim.notify((kind == 'message' and 'Message sent to ' or 'Review sent to ') .. (session.title or session.id))
    end)
  end)
end

local function send_with_comment(kind)
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
    -- Open the recipient picker after the comment editor closes.
    vim.schedule(guarded(function() send(root, kind) end))
  end, kind == 'message' and ' Message to OpenCode ' or ' General review comment ')
end

command('ReviewSend', function() send(current_root(), 'review') end)
command('ReviewSendWithComment', function() send_with_comment('feedback') end)
command('AgentSend', function() send(current_root(), 'message') end)
command('AgentSendWithComment', function() send_with_comment('message') end)
command('ReviewResend', function()
  local root = current_root()
  pick_batch(root, 'Resend archived review', function(batch) send(root, batch.kind, batch) end)
end)

return {
  setup = function(opts) config = vim.tbl_extend('force', defaults, opts or {}) end,
}
