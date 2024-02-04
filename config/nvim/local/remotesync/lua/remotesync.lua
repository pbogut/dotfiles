local command = vim.api.nvim_create_user_command
local fn = vim.fn
local config = require('pbogut.config')

local remotes = {}
for _, remote in pairs(config.get('sync.remotes', {})) do
  remotes[remote.name] = remote.uri
end

local function sync(remote)
  if remote and remotes and remotes[remote] then
    local cmd = { 'rsync', fn.expand('%:.'), remotes[remote] .. '/' .. fn.expand('%:.') }
    fn.jobstart(cmd, {
      on_exit = function()
        print('File synced to ' .. remote .. ' (' .. fn.expand('%:.') .. ')')
      end,
    })
  end
end

if config.get('sync.autosync.enabled', false) then
  local remote = config.get('sync.autosync.remote', '')
  local filters = config.get('sync.autosync.filters', {})

  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = filters,
    callback = function()
      vim.cmd.RemoteSync(remote)
    end,
  })
end

vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('x_remotesync', { clear = true }),
  pattern = '*',
  callback = function()
    local remote = vim.b.sync_remote or ''
    if remote == '' then
      remote = vim.g.sync_remote or ''
    end
    sync(remote)
  end,
})

function _G.remotesync_complete(lead)
  local keys = {}

  for k in pairs(remotes) do
    if k:sub(1, #lead) == lead then
      keys[#keys + 1] = k
    end
  end

  return keys
end

command('RemoteSync', function(opt)
  local name = opt.args
  local halt = false
  if name:match('prod') then
    halt = 1
      ~= fn.confirm('You are about to do some changes, are you sure you know what you are doing?', 'Yes\nNo', 'No')
  end
  if not halt then
    if opt.bang then
      vim.g.sync_remote = opt.args
    else
      vim.b.sync_remote = opt.args
    end
    vim.defer_fn(function()
      print('Syncing...')
      sync(name)
    end, 1)
  else
    vim.defer_fn(function()
      vim.notify('File sync aborted!', vim.log.levels.WARN, { title = 'RemoteSync' })
    end, 1)
    vim.defer_fn(function()
      print(' ')
    end, 1000)
  end
end, { complete = 'customlist,v:lua.remotesync_complete', nargs = 1, bang = true })

command('RemotePush', function(opt)
  local name = opt.args
  local halt = false
  if name:match('prod') then
    halt = 1
      ~= fn.confirm('You are about to do some changes, are you sure you know what you are doing?', 'Yes\nNo', 'No')
  end
  if not halt then
    vim.defer_fn(function()
      print('Syncing...')
      sync(name)
    end, 1)
  else
    vim.defer_fn(function()
      vim.notify('File push aborted!', vim.log.levels.WARN, { title = 'RemoteSync' })
    end, 1)
    vim.defer_fn(function()
      print(' ')
    end, 1000)
  end
end, { complete = 'customlist,v:lua.remotesync_complete', nargs = 1, bang = false })
