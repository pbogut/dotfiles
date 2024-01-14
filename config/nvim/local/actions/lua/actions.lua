local M = {}
local command = vim.api.nvim_create_user_command
local config = require('pbogut.config')
local action_output = 'actions://output'

function M.run_action(action, opts)
  opts = opts or {}
  if type(action) ~= 'string' then
    print('You need to provide action name.')
  else
    local cmds = M.get_cmds_for_action(action)
    M.run_cmds(cmds, opts)
  end
end

function M.get_cmds_for_action(action)
  local result = {}
  if type(action) == 'string' then
    result = config.get('actions.' .. action, {})
  end

  return result
end

function M.list_actions()
  local actions = {}
  for action, _ in pairs(config.get('actions', {})) do
    actions[#actions + 1] = action
  end

  return actions
end

local start_job = function(job)
  vim.fn.jobstart(job.command, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = job.on_stdout,
    on_stderr = job.on_stderr,
    on_exit = job.on_exit,
  })
end

local function get_bufnr_by_name(name)
  local bufs = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(bufs) do
    local bname = vim.api.nvim_buf_get_name(bufnr)
    if bname == name then
      return bufnr
    end
  end

  return nil
end

local function get_output_bufnr()
  local bufnr = get_bufnr_by_name(action_output)
  if bufnr then
    return bufnr
  end

  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, action_output)
  vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'delete')

  return bufnr
end

local function get_visible_windows()
  local tabnr = vim.fn.tabpagenr()
  local tabinfo = vim.fn.gettabinfo()
  for _, tabopts in pairs(tabinfo) do
    if tabopts.tabnr == tabnr then
      return tabopts.windows
    end
  end
  return {}
end
local function is_output_visible()
  local bufnr = get_output_bufnr()
  for _, winid in pairs(get_visible_windows()) do
    if vim.api.nvim_win_get_buf(winid) == bufnr then
      return true
    end
  end
  return false
end

local function show_output_buffer()
  if not is_output_visible() then
    vim.cmd.vsplit()
    vim.cmd.enew()
    vim.cmd.buffer(get_output_bufnr())
  end
end

function M.run_cmds(cmds, opts)
  opts = opts or {}
  if opts.cmd_print == nil then
    opts.cmd_print = true
  end
  local out = function(msg)
    if opts.cmd_print then
      vim.notify(msg, vim.log.levels.INFO, { title = 'Actions', trim = true })
    end
  end
  local msg_run = opts.msg_run or 'Run command'
  local on_done = opts.on_done or function(_, _) end
  local on_exit = opts.on_exit or function(_, _) end

  if type(cmds) ~= 'table' or #cmds == 0 then
    out('Nothing to run.')
    return
  end

  out(msg_run .. ' 1/' .. #cmds .. ' : ' .. cmds[1])
  vim.g._actions_status = '1/' .. #cmds

  local jobs = {}

  --[[ local winnr = nil ]]
  local bufnr = get_output_bufnr()

  vim.keymap.set('n', 'q', '<cmd>bdelete!<cr>', { buffer = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'Output:' })

  local filter_empty = function(out)
    local result = {}
    for _, line in pairs(out) do
      if line ~= '' then
        result[#result + 1] = line
      end
    end
    return result
  end

  local print_out = function(out)
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, filter_empty(out))
    --[[ vim.api.nvim_win_set_cursor(winnr, { vim.api.nvim_buf_line_count(bufnr), 0 }) ]]
  end

  local on_out = function(_, out)
    print_out(out)
  end

  for i, cmd in ipairs(cmds) do
    ---@diagnostic disable-next-line: redefined-local
    local opts = {
      command = cmd,
      on_stdout = on_out,
      on_stderr = on_out,
      on_exit = function(j, res)
        out(msg_run .. ' ' .. i + 1 .. '/' .. #cmds .. ' : ' .. cmds[i + 1])
        vim.g._actions_status = i + 1 .. '/' .. #cmds
        on_exit(j, res)
        if jobs[i + 1] then
          print_out({ '>> ' .. jobs[i + 1].command })
          start_job(jobs[i + 1])
        end
      end,
    }

    if i == #cmds then
      opts.on_exit = function(j, res)
        out(msg_run .. ' ' .. i .. '/' .. #cmds .. ' : DONE')
        vim.g._actions_status = ''
        print_out({ '--', 'press [q] for exit' })
        on_done(j, res)
      end
    end

    jobs[#jobs + 1] = opts
  end

  if jobs[1] then
    print_out({ '>> ' .. jobs[1].command })
    start_job(jobs[1])
  end
end

function M.pick_action()
  local actions = M.list_actions()
  if #actions == 0 then
    vim.notify('No actions found.', vim.log.levels.INFO, { title = 'Actions' })
    return
  end
  table.sort(actions, function(a1, a2)
    return a1 < a2
  end)
  vim.ui.select(actions, { prompt = 'Select action: ' }, function(action)
    if action then
      M.run_action(action)
    end
    vim.cmd.stopinsert()
  end)
end

function _G.action_complete(lead)
  local result = {}
  for _, item in ipairs(M.list_actions()) do
    if item:sub(1, #lead) == lead then
      result[#result + 1] = item
    end
  end
  return result
end

command('Action', function(opt)
  if opt.bang then
    show_output_buffer()
  end
  M.run_action(opt.args)
end, { complete = 'customlist,v:lua.action_complete', nargs = '?', bang = true })

local augroup = vim.api.nvim_create_augroup('x_actions', { clear = true })
vim.api.nvim_create_autocmd('VimEnter', {
  group = augroup,
  pattern = '*',
  callback = function()
    local cmds = M.get_cmds_for_action('quick_init')
    if #cmds > 0 then
      M.run_cmds(cmds)
    end
  end,
})

return M
