local fn = vim.fn
local o = vim.o

o.title = true

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('x_title', { clear = true }),
  pattern = '*',
  callback = function()
    local user = os.getenv('USER') .. ''
    local host = fn.hostname()

    local base_dir = fn.system('base-dir'):gsub('\n', '')
    local cwd = fn.substitute(base_dir, os.getenv('HOME'), '~', 'g')

    if os.getenv('SSH_CLIENT') or os.getenv('SSH_TTY') then
      o.titlestring = user .. '@' .. host .. ':nvim:' .. cwd
    else
      local nvim_addr = vim.v.servername or ''
      local addr = fn.substitute(nvim_addr, [[/run/user/[0-9]\+/nvim\.\(.*\)\.0]], [[\1]], 'g')
      -- force updat a sworkoround for zellij title not being updated properly
      o.titlestring = ""
      vim.schedule(function()
        o.titlestring = user .. '@' .. host .. ':nvim:' .. addr .. ':' .. cwd
      end)
    end
  end,
})
