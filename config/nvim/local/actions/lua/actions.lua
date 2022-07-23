local M = {}
local config = require('config')
local Job = require('plenary.job')
local u = require('utils')

function M.run_action(action)
  local cmds = M.get_cmds_for_action(action)
  M.run_cmds(cmds)
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

function M.run_cmds(cmds, opts)
  opts = opts or {}
  local module = opts.module or 'actions'
  local msg_run = opts.msg_run or 'Run command'
  local on_done = opts.on_done or function(_, _) end
  local on_exit = opts.on_exit or function(_, _) end
  print('[' .. module .. '] ' .. msg_run .. ' 1/' .. #cmds .. ' : ' .. cmds[1])
  vim.g._actions_status = '1/' .. #cmds

  local jobs = {}

  for i, cmd in ipairs(cmds) do
    ---@diagnostic disable-next-line: redefined-local
    local opts = {
      command = 'bash',
      args = { '-c', cmd },
      on_exit = function(j, res)
        print('[' .. module .. '] ' .. msg_run .. ' ' .. i + 1 .. '/' .. #cmds .. ' : ' .. cmds[i + 1])
        vim.g._actions_status = i + 1 .. '/' .. #cmds
        on_exit(j, res)
      end,
    }

    if i == #cmds then
      opts.on_exit = function(j, res)
        print('[' .. module .. '] ' .. msg_run .. ' ' .. i .. '/' .. #cmds .. ' : DONE')
        vim.g._actions_status = ''
        on_done(j, res)
      end
    end

    jobs[#jobs + 1] = Job:new(opts)
  end

  Job.chain(unpack(jobs))
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

u.command('Action', function(name)
  M.run_action(name)
end, { complete = 'customlist,v:lua.action_complete', nargs = '?', bang = false, qargs = true })

return M
