-- nvim --headless -u NONE -i NONE -n -l assets/tests/nvim_agent_review.lua
local fn = vim.fn
local plugin = fn.fnamemodify('dot_config/nvim/local/agent-review/lua/agent-review.lua', ':p')
local tmp = fn.tempname()
vim.env.XDG_STATE_HOME = tmp .. '/state'
local root = tmp .. '/project'
fn.mkdir(root .. '/.git', 'p')
fn.writefile({ 'one', 'two', 'three' }, root .. '/file')
local review = dofile(plugin)
vim.cmd.edit(root .. '/file')
local cwd = root .. '/nested dir'
fn.mkdir(cwd)
vim.cmd.lcd(fn.fnameescape(cwd))

local function saved()
  local path = fn.glob(fn.stdpath('state') .. '/agent-review/*.json')
  return vim.json.decode(fn.readfile(path)[1])
end

local function comment(range, text)
  local source = vim.api.nvim_get_current_win()
  vim.cmd(range .. 'ReviewComment')
  assert(vim.api.nvim_win_get_config(0).relative == 'win')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, '\n'))
  vim.cmd.write()
  assert(vim.api.nvim_get_current_win() == source)
end

local choices, prompt, acknowledge = {}, nil, nil
local switch
local herdr, picker, picker_title
vim.ui.select = function(items, opts, reply)
  if items[1] and items[1].location then
    picker, picker_title = vim.tbl_map(opts.format_item, items), opts.prompt
  end
  local item = items[table.remove(choices, 1)]
  if item then assert(opts.format_item(item) ~= '') end
  reply(item)
end
local function choose(...) choices = { ... } end
vim.system = function(args, opts, cb)
  local function respond(data) cb({ code = 0, stdout = vim.json.encode(data), stderr = '' }) end
  if args[1] == 'herdr-app' then
    assert(herdr, 'Herdr must be opt-in')
    if herdr == 'missing' then error('ENOENT') end
    respond({
      spaces = herdr == 'empty' and {} or {
        {
          id = 'w1',
          folder = root,
          tabs = {
            { name = 'oc-1', terminals = { { terminal = 't1', app = 'opencode' } } },
            { name = 'oc-2', terminals = { { terminal = 't2', app = 'opencode' } } },
          },
        },
      },
    })
  elseif args[1] == 'hc' then
    respond({
      result = {
        value = {
          slots = {
            ['w1/oc-1'] = { terminal = 'old', sessionID = 'sesA' },
            ['w1/oc-2'] = { terminal = 't2', sessionID = 'sesB' },
          },
        },
      },
    })
  elseif args[3] == 'session.list' then
    assert(opts.cwd == root and vim.list_contains(args, 'directory=' .. root))
    if vim.list_contains(args, 'cursor=next') then
      respond({ data = { { title = 'Agent B', id = 'sesB', location = { directory = root } } } })
    else
      respond({
        data = {
          { title = 'Sibling', id = 'sesOther', location = { directory = tmp .. '/other' } },
          { title = 'Agent A', id = 'sesA', location = { directory = root } },
        },
        cursor = { next = 'next' },
      })
    end
  elseif args[3] == 'session.switchAgent' then
    assert(opts.cwd == root)
    switch = {
      id = args[5]:match('^sessionID=(.+)$'),
      agent = vim.json.decode(args[7]).agent,
      reply = function(ok) cb({ code = ok and 0 or 1, stdout = '', stderr = ok and '' or 'unknown agent' }) end,
    }
  elseif args[3] == 'session.prompt' then
    local id = args[5]:match('^sessionID=(.+)$')
    prompt = { id = id, text = vim.json.decode(args[7]).text }
    acknowledge = function(ok)
      if ok then
        respond({ data = { sessionID = id } })
      else
        cb({ code = 1, stderr = 'offline' })
      end
    end
  else
    error('Unexpected request: ' .. vim.inspect(args))
  end
end
local function wait(f) assert(vim.wait(1000, f), 'Timed out waiting for review') end
local function start_send(command)
  acknowledge = nil
  vim.cmd(command)
  wait(function() return acknowledge ~= nil end)
end
local function expect_switch(command, agent, id)
  switch, acknowledge = nil, nil
  vim.cmd(command)
  wait(function() return switch end)
  assert(switch.agent == agent and switch.id == id and not acknowledge)
end
comment('1,2', 'Why both?\n\nWhat about null?')
vim.cmd('1ReviewComment')
assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') == 'Why both?\n\nWhat about null?')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'discard this' })
vim.cmd('normal q')
assert(saved().draft[1].text == 'Why both?\n\nWhat about null?')
comment('1', 'Explain both')
assert(#saved().draft == 1 and saved().draft[1].text == 'Explain both')
choose(2)
start_send('ReviewSend')
assert(picker_title == 'Send feedback')
local original = prompt.text
assert(
  prompt.id == 'sesB' and original:find('file:1-2', 1, true) and original:find('two') and original:find('Explain both')
)
comment('3', 'Work in progress')
acknowledge(true)
wait(function() return #saved().history == 1 end)
assert(#saved().draft == 1 and saved().draft[1].text == 'Work in progress', vim.inspect(saved()))
assert(saved().history[1].session.id == 'sesB')

review.setup({ review_begin = 'Start', review_end = 'Finish', feedback_mode = 'reviewer' })
choose(1, 2)
expect_switch('ReviewResend', 'reviewer', 'sesA')
switch.reply(true)
wait(function() return acknowledge end)
assert(vim.deep_equal(picker, { '* Agent B  sesB', '  Agent A  sesA' }), vim.inspect(picker))
assert(prompt.id == 'sesA' and prompt.text == original)
acknowledge(true)
wait(function() return #saved().history == 2 end)
assert(saved().draft[1].text == 'Work in progress')
choose(1)
vim.cmd('ReviewRestore!')
assert(#saved().draft == 2 and saved().history[1].kind == 'before merge')
assert(#saved().history[1].comments == 1)
comment('1', 'Revised question')
choose(2)
vim.cmd('ReviewRestore!')
assert(#saved().draft == 2 and saved().draft[2].text == 'Revised question')
choose(2)
vim.cmd('ReviewRestore')
assert(#saved().draft == 1 and saved().draft[1].text == 'Work in progress')
assert(#saved().history[1].comments == 2 and saved().history[1].kind == 'unsent')

choose(0)
vim.cmd.ReviewRestore()
assert(saved().history[1].kind == 'unsent' and #saved().draft == 1)
local failed = false
vim.notify = function(_, level)
  if level == vim.log.levels.ERROR then failed = true end
end
review.setup({ feedback_mode = 'plan', approval_mode = 'build' })
choose(1)
expect_switch('ReviewSend', 'plan', 'sesA')
local unsent = saved()
switch.reply(false)
wait(function() return failed end)
assert(not acknowledge and vim.deep_equal(saved(), unsent))
failed = false
review.setup({ approval_mode = 'build' }) -- Feedback has no mode override.
choose(1)
start_send('ReviewSend')
acknowledge(false)
wait(function() return failed end)
assert(#saved().draft == 1 and saved().history[1].kind == 'unsent')

-- Load from disk as on a new launch, after the file's lines have moved.
fn.writefile({ 'zero', 'one', 'two', 'three' }, root .. '/file')
dofile(plugin)
vim.cmd('edit!')
local marks = vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces()['agent-review'], 0, -1, {})
assert(#marks == 1 and marks[1][2] == 3, 'missing restored gutter mark')

comment('4', '') -- remove the remaining line comment
local function general(text)
  vim.cmd.ReviewSendWithComment()
  assert(vim.api.nvim_win_get_config(0).relative == 'editor')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, '\n'))
  vim.cmd.write()
end
review = dofile(plugin)
review.setup({ review_begin = '', review_end = '' })
choose(1)
acknowledge = nil
general('One thought\nfor the whole review.')
wait(function() return acknowledge end)
assert(prompt.text == 'One thought\nfor the whole review.')
acknowledge(true)
wait(function() return #saved().draft == 0 end)

vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'A', 'B', 'C', 'D', 'E' })
comment('1,5', 'Whole file')
comment('2,4', 'Three lines')
review.setup({ review_begin = 'Begin here', review_end = 'End here' })
choose(2)
acknowledge = nil
general('General\nfeedback')
wait(function() return acknowledge end)
assert(prompt.text == table.concat({
  'Begin here',
  'General\nfeedback',
  'file:1-5\n    A\n    ...\n    E\n\nWhole file',
  'file:2-4\n    B\n    C\n    D\n\nThree lines',
  'End here',
}, '\n\n'), prompt.text)
acknowledge(true)
wait(function() return #saved().draft == 0 end)
local before = #saved().history
picker, prompt = nil, nil
choose(0)
vim.cmd.ReviewSend()
wait(function() return picker ~= nil end)
assert(picker_title == 'Approve review' and not prompt and #saved().history == before)
review.setup({ review_approve = 'LGTM', feedback_mode = 'plan', approval_mode = 'build' })
choose(1)
expect_switch('ReviewSend', 'build', saved().history[1].session.id)
switch.reply(true)
wait(function() return acknowledge end)
assert(prompt.text == 'LGTM' and #saved().history == before)
acknowledge(true)
wait(function() return saved().history[1].kind == 'approved' end)
assert(saved().history[1].message == 'LGTM')
comment('1', 'Still pending after dismissing the picker')
review.setup({ feedback_mode = 'plan' }) -- Resending an approval must not use the feedback mode.
choose(1, 2)
start_send('ReviewResend')
assert(prompt.text == 'LGTM' and picker_title == 'Approve review')
acknowledge(true)
wait(function() return #saved().history == before + 2 end)
assert(saved().history[1].kind == 'approved' and #saved().draft == 1)
review.setup({ filter_herdr_app = true })
for _, mode in ipairs({ 'live', 'empty', 'missing' }) do
  herdr, picker = mode, nil
  choose(0)
  vim.cmd.ReviewSend()
  wait(function() return picker ~= nil end)
  assert(#picker == (mode == 'live' and 1 or 2), vim.inspect(picker))
  if mode == 'live' then assert(picker[1]:find('oc-2 · Agent B', 1, true)) end
end

local errors = {}
vim.notify = function(msg, level)
  if level == vim.log.levels.ERROR then table.insert(errors, msg) end
end
local statefile = fn.glob(fn.stdpath('state') .. '/agent-review/*.json')
vim.cmd('2ReviewComment')
local editor = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(editor, 0, -1, false, { 'Keep this on save failure' })
assert(fn.rename(statefile, statefile .. '.bak') == 0)
fn.mkdir(statefile) -- An atomic file rename cannot replace a directory.
vim.cmd.write()
assert(#errors == 1 and vim.api.nvim_get_current_buf() == editor and vim.bo.modified)
assert(fn.getline(1) == 'Keep this on save failure')
assert(fn.delete(statefile, 'd') == 0 and fn.rename(statefile .. '.bak', statefile) == 0)
vim.cmd.write()
assert(saved().draft[2].text == 'Keep this on save failure')

-- The send acknowledgement runs after the command and picker have both returned.
choose(1)
start_send('ReviewSend')
assert(fn.rename(statefile, statefile .. '.bak') == 0)
fn.mkdir(statefile)
acknowledge(true)
wait(function() return #errors == 2 end)
assert(fn.delete(statefile, 'd') == 0 and fn.rename(statefile .. '.bak', statefile) == 0)
assert(#saved().draft == 2)

fn.writefile({ 'broken json' }, statefile)
dofile(plugin)
vim.cmd('edit!')
assert(#errors == 3 and errors[3] == 'Invalid review file: ' .. statefile)
assert(fn.readfile(statefile)[1] == 'broken json')

vim.cmd.lcd(fn.fnameescape(tmp))
vim.cmd.edit(fn.fnameescape(tmp .. '/outside'))
for _, cmd in ipairs({ 'ReviewSend', 'ReviewSendWithComment', 'ReviewRestore', 'ReviewResend' }) do
  errors = {}
  vim.cmd(cmd)
  assert(vim.deep_equal(errors, { 'Review needs a Git worktree' }))
end
fn.delete(tmp, 'rf')
print('agent-review tests passed')
