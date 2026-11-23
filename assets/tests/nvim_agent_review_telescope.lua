-- TELESCOPE_DIR=... PLENARY_DIR=... nvim --headless -u NONE -i NONE -n -l assets/tests/nvim_agent_review_telescope.lua
local api, fn = vim.api, vim.fn
vim.opt.rtp:prepend(assert(vim.env.TELESCOPE_DIR, 'Set TELESCOPE_DIR to the telescope.nvim checkout'))
vim.opt.rtp:prepend(assert(vim.env.PLENARY_DIR, 'Set PLENARY_DIR to the plenary.nvim checkout'))
local tmp = fn.tempname()
vim.env.XDG_STATE_HOME = tmp .. '/state'
local root = tmp .. '/project'
fn.mkdir(root .. '/.git', 'p')
dofile('dot_config/nvim/local/agent-review/lua/agent-review.lua').setup({ filter_herdr_app = true })
vim.cmd.edit(root .. '/file')
require('telescope').setup({ defaults = { sorting_strategy = 'ascending' } })
local actions = require('telescope.actions')
local state = require('telescope.actions.state')
local list_sessions, list_tabs, delayed, sent
local errors = {}
vim.notify = function(msg, level)
  if level == vim.log.levels.ERROR then table.insert(errors, msg) end
end
vim.system = function(args, _, cb)
  local function reply(data) cb({ code = 0, stdout = vim.json.encode(data), stderr = '' }) end
  if args[1] == 'herdr-app' then
    list_tabs = function() reply({ spaces = {} }) end
  elseif args[3] == 'session.list' then
    list_sessions = function()
      reply({
        data = {
          { id = 'sesA', title = 'Fix tests', location = { directory = root } },
          { id = 'sesB', title = 'Fix tests', location = { directory = root } },
        },
      })
    end
  elseif args[3] == 'session.message.list' then
    assert(vim.list_contains(args, 'type=assistant'))
    if vim.list_contains(args, 'sessionID=sesA') then
      delayed = function() reply({ data = {} }) end
    elseif vim.list_contains(args, 'cursor=older') then
      assert(not vim.list_contains(args, 'order=desc'))
      reply({
        data = {
          {
            type = 'assistant',
            content = {
              { type = 'text', text = 'Fixed the flaky test.' },
              { type = 'reasoning', text = 'private' },
              { type = 'text', text = 'Ready for review.' },
            },
          },
        },
      })
    else
      assert(vim.list_contains(args, 'order=desc'))
      reply({ data = { { type = 'assistant', content = { { type = 'tool' } } } }, cursor = { next = 'older' } })
    end
  elseif args[3] == 'session.prompt' then
    sent = args[5]
    reply({ data = { sessionID = 'sesB' } })
  else
    error('Unexpected request: ' .. vim.inspect(args))
  end
end
local function wait(f) assert(vim.wait(2000, f), 'Timed out: ' .. vim.inspect(errors)) end
local function open_loading()
  list_sessions, list_tabs, delayed = nil, nil, nil
  vim.cmd.ReviewSend()
  local buf = api.nvim_get_current_buf()
  local picker = state.get_current_picker(buf)
  assert(picker.results_title == 'Loading sessions...' and not picker:get_selection())
  assert(list_sessions and list_tabs, 'Session and tab lookups should both be in flight')
  return buf, picker
end
local buf, picker = open_loading()
actions.select_default(buf) -- No selectable loading row.
assert(api.nvim_get_current_buf() == buf and not sent)
actions.close(buf)
list_tabs()
list_sessions()
buf, picker = open_loading()
picker:set_prompt('sesB')
list_tabs()
list_sessions()
wait(function() return picker:get_selection() and picker:get_selection().value.id == 'sesB' end)
assert(picker.manager:num_results() == 1 and picker.results_title == 'Sessions' and not delayed)
actions.close(buf)
buf, picker = open_loading()
list_sessions()
list_tabs()
wait(function() return delayed end)
actions.close(buf)
delayed() -- Closing with a preview in flight must not send or touch a deleted buffer.
buf, picker = open_loading()
list_tabs()
list_sessions()
local function preview()
  local win = picker.layout.preview.winid
  return table.concat(api.nvim_buf_get_lines(api.nvim_win_get_buf(win), 0, -1, false), '\n')
end
wait(function() return preview() == 'Loading reply...' end)
actions.move_selection_next(buf)
local expected = 'Fixed the flaky test.\n\nReady for review.'
wait(function() return preview() == expected end)
delayed() -- A's response arrives while B is highlighted.
local processed = false
vim.schedule(function() processed = true end)
wait(function() return processed end)
assert(preview() == expected and not sent)
actions.move_selection_previous(buf)
wait(function() return preview() == 'No assistant reply yet.' end)
actions.move_selection_next(buf)
wait(function() return preview() == expected end)
actions.select_default(buf)
wait(function() return fn.glob(tmp .. '/state/nvim/agent-review/*.json') ~= '' end)
assert(sent == 'sessionID=sesB')
local source = api.nvim_get_current_win()
vim.cmd.ReviewSendWithComment()
api.nvim_buf_set_lines(0, 0, -1, false, { 'One more thing' })
vim.cmd.write()
wait(function() return vim.bo.filetype == 'TelescopePrompt' end)
picker = state.get_current_picker(api.nvim_get_current_buf())
assert(picker.original_win_id == source, 'The picker should return to the source window, not the closed comment editor')
actions.close(picker.prompt_bufnr)
assert(api.nvim_get_current_win() == source)
assert(#errors == 0, vim.inspect(errors))
fn.delete(tmp, 'rf')
print('agent-review Telescope tests passed')
