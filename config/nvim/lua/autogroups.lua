local u = require('utils')
local bo = vim.bo
local wo = vim.wo
local o = vim.o
local cmd = vim.cmd
local fn = vim.fn

local config_group = {
  -- fix terminal display
  VimEnter = {
    {
      '*',
      function()
        -- highlights
        u.highlights({
          Folded = { term = 'NONE', cterm = 'NONE',  gui = 'NONE' }
        })
      end
    },
  },
  TermOpen = {
    {
      '*',
      function()
        wo.number = false
        wo.relativenumber = false
        wo.signcolumn = "no"
        wo.cursorline = false
        wo.cursorcolumn = false
        o.laststatus = 0
        o.showmode = false

        u.augroup('x_termopen', {
          BufLeave = {'<buffer>', function()
            o.laststatus = 2
            o.showmode = true
          end},
          BufEnter = {'<buffer>', function()
            o.laststatus = 0
            o.showmode = false
          end},
        })
        -- used to have display errors with terminal
        -- @remove below if not happening anymore
        -- " \  :exec('silent! normal! <c-\><c-n>a')
        -- " \| :startinsert
      end
    },
  },
  ['WinEnter,BufEnter'] = {
    {
      '*',
      function()
        fn.matchadd('Todo', '@todo\\>')
        fn.matchadd('Todo', '@fixme\\>')
        fn.matchadd('Error', '@debug\\>')
      end
    },
  },
  FileType = {
    {
      'html,css,scss,xml,java,elixir,eelixir,c,php,php.phtml,sql,blade,elm',
      function()
        u.set_indent(4)
      end
    },
    {
      'sh,vue,javascript,vim,lua,yaml,yaml.docker-compose,ruby',
      function()
        u.set_indent(2)
      end
    },
    {
      'mail',
      [[
        setlocal spell spelllang=en_gb
        setlocal textwidth=72
        execute('normal gg')
        call search('^$')
      ]]
    },
    {
      'go',
      function()
        u.set_indent(2, true)
      end
    },
    {
      'php',
      function()
        bo.iskeyword = '@,48-57,_,192-255,$'
      end
    },
    {
      'markdown',
      function()
        cmd('setlocal spell spelllang=en_gb')
      end
    },
  }
}

u.augroup('x_autogroups', config_group)
