local u = require('utils')
local fn = vim.fn
local config = require('config')

local remotes = config.get('sync.remotes')

local config_group = {
  BufWritePost = {
    {
      '*',
      function()
        local remote = vim.b.sync_remote or ""
        if remote == "" then
          remote = vim.g.sync_remote or ""
        end

        if remote and remotes and remotes[remote] then
          local cmd = {'scp', fn.expand('%:.'), remotes[remote] .. '/' .. fn.expand('%:.')}
          fn.jobstart(cmd, {
            on_exit = function()
              print('File synced to ' .. remote .. ' (' .. fn.expand('%:.') .. ')')
            end
          })
        end
      end
    },
  },
}

function _G.remotesync_complete()
  local keys = {}
  for k in pairs(remotes) do keys[#keys+1] = k end
  return keys
end

u.augroup('x_remotesync', config_group)
u.command('RemoteSync', function(bang, name)
  if bang then
    vim.g.sync_remote = name
  else
    vim.b.sync_remote = name
  end
end, {complete = 'customlist,v:lua.remotesync_complete', nargs = '?', bang = true, qargs = true})

-- -complete=custom
