local M = {}
local command = vim.api.nvim_create_user_command
local config = require('config')
local u = require('utils')

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

function M.run_cmds(cmds, opts)
  opts = opts or {}
  if opts.cmd_print == nil then
    opts.cmd_print = true
  end
  local out = function(msg)
    if opts.cmd_print then
      print(msg)
    end
  end
  local module = opts.module or 'actions'
  local msg_run = opts.msg_run or 'Run command'
  local on_done = opts.on_done or function(_, _) end
  local on_exit = opts.on_exit or function(_, _) end
  local show_output = opts.show_output or false

  if type(cmds) ~= 'table' or #cmds == 0 then
    out('[' .. module .. '] Nothing to run.')
    return
  end

  out('[' .. module .. '] ' .. msg_run .. ' 1/' .. #cmds .. ' : ' .. cmds[1])
  vim.g._actions_status = '1/' .. #cmds

  local jobs = {}

  local winnr = nil
  local bufnr = nil

  if show_output then
    vim.cmd.vsplit()
    vim.cmd.enew()
    bufnr = vim.fn.bufnr()
    winnr = vim.api.nvim_get_current_win()

    vim.keymap.set('n', 'q', '<cmd>bdelete!<cr>', { buffer = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'Output:' })
  end

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
    if show_output then
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, filter_empty(out))
      vim.api.nvim_win_set_cursor(winnr, { vim.api.nvim_buf_line_count(bufnr), 0 })
    end
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
        out('[' .. module .. '] ' .. msg_run .. ' ' .. i + 1 .. '/' .. #cmds .. ' : ' .. cmds[i + 1])
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
        out('[' .. module .. '] ' .. msg_run .. ' ' .. i .. '/' .. #cmds .. ' : DONE')
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
  M.run_action(opt.args, { show_output = opt.bang })
end, { complete = 'customlist,v:lua.action_complete', nargs = '?', bang = true })

return M
