local u = require('utils')
local fn = vim.fn
local o = vim.o

o.title = true

u.augroup('x_title', {
  BufEnter = {
    {
      '*',
      function()
        local file = fn.expand('%:~')
        local user = os.getenv('USER') .. ''
        local host = fn.hostname()
        if file == "" then
          file = fn.substitute(fn.getcwd(), os.getenv('HOME'), '~', 'g')
        end

        if os.getenv('SSH_CLIENT') or os.getenv('SSH_TTY') then
          o.titlestring = user .. '@' ..  host .. ":nvim:" .. file
        else
          local nvim_addr = os.getenv('NVIM_LISTEN_ADDRESS') or ''
          local tmp_dir = os.getenv('TMPDIR') .. ''
          local addr = fn.substitute(nvim_addr, tmp_dir .. [[/nvim\(.*\)\/0$]], [[\1]], 'g')
          o.titlestring = user .. '@' ..  host .. ':nvim:' ..  addr .. ':' .. file
        end
      end
    }
  }
})
