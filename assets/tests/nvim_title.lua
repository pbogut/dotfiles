-- Run from the repository root: nvim --headless -u NONE -i NONE -n -l assets/tests/nvim_title.lua
local source = 'dot_config/nvim/lua/pbogut/settings/title.lua'
local hash = '0123456789abcdef'

local function title_for(address, runtime_dir, ssh)
  local callback
  local options = {}
  local env = {
    USER = 'user',
    HOME = '/home/user',
    PROJECTS = '/projects',
    XDG_RUNTIME_DIR = runtime_dir,
    SSH_TTY = ssh,
  }
  local sandbox = {
    os = { getenv = function(name) return env[name] end },
    vim = {
      o = options,
      v = { servername = address },
      uv = { getuid = function() return 1000 end },
      pesc = vim.pesc,
      fn = {
        hostname = function() return 'host' end,
        system = function(command)
          assert(command == 'base-dir')
          return '/projects/example\n'
        end,
        substitute = vim.fn.substitute,
      },
      api = {
        nvim_create_augroup = function() return 1 end,
        nvim_create_autocmd = function(_, spec) callback = spec.callback end,
      },
      schedule = function(fn) fn() end,
    },
  }
  setfenv(assert(loadfile(source)), sandbox)()
  assert(options.title)
  callback()
  return options.titlestring
end

for _, runtime in ipairs({ '/run/user/1000', '/tmp/runtime.with-patterns+[x]' }) do
  local address = runtime .. '/herdr-nvim/' .. hash .. '/w2C.sock'
  local title = title_for(address, runtime)
  assert(title == 'user@host:nvim:H/' .. hash .. '/w2C:~p/example', title)
end

local address = '/run/user/1000/herdr-nvim/' .. hash .. '/w2C.sock'
assert(title_for(address) == 'user@host:nvim:H/' .. hash .. '/w2C:~p/example')
assert(title_for(address, '') == 'user@host:nvim:H/' .. hash .. '/w2C:~p/example')
assert(title_for(address, nil, '/dev/pts/1') == 'user@host:nvim:~p/example')

for _, id in ipairs({ '123', 'herdr-w2C' }) do
  assert(title_for('/run/user/1000/nvim.' .. id .. '.0') == 'user@host:nvim:' .. id .. ':~p/example')
end

for _, other in ipairs({
  '/tmp/nvim.sock',
  '/tmp/herdr-nvim/' .. hash .. '/w2C.sock',
  '/run/user/1000/herdr-nvim/short/w2C.sock',
  '/run/user/1000/herdr-nvim/' .. hash .. '/w2C/extra.sock',
}) do
  assert(title_for(other) == 'user@host:nvim:' .. other .. ':~p/example')
end

print('Neovim title tests passed')
