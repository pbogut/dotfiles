local u = require('utils')
local fn = vim.fn
local o = vim.o

o.title = true

u.augroup('x_title', {
  BufEnter = {
    {
      '*',
      function()
        local user = os.getenv('USER') .. ''
        local host = fn.hostname()
        local cwd = fn.substitute(fn.getcwd(), os.getenv('HOME'), '~', 'g')

        if os.getenv('SSH_CLIENT') or os.getenv('SSH_TTY') then
          o.titlestring = user .. '@' ..  host .. ":nvim:" .. cwd
        else
          local nvim_addr = vim.v.servername or ''
          local addr = fn.substitute(nvim_addr, [[/run/user/[0-9]\+/nvim\.\(.*\)\.0]], [[\1]], 'g')
          o.titlestring = user .. '@' ..  host .. ':nvim:' ..  addr .. ':' .. cwd
        end
      end
    }
  }
})
