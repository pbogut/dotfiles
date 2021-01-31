local u = require('utils')
local b = vim.b
local bo = vim.bo
local wo = vim.wo
local cmd = vim.cmd
local fn = vim.fn

local config_group = {
  -- fix terminal display
  TermOpen = {
    {'*', function()
        wo.number = false
        wo.relativenumber = false
        wo.signcolumn = "no"
      end
    }
  },
  FileType = {
    { '*', function()
        fn.matchadd('Todo', '@todo\\>')
        fn.matchadd('Todo', '@fixme\\>')
        fn.matchadd('Error', '@debug\\>')
      end
    },
    { 'html,css,scss,xml,java,elixir,eelixir,c,php,php.phtml,sql,blade,elm',
      function()
        u.set_indent(4)
      end
    },
    { 'sh,vue,javascript,vim,lua,yaml,yaml.docker-compose,ruby',
      function()
        u.set_indent(2)
      end
    },
    { 'mail', [[
        setlocal spell spelllang=en_gb
        setlocal textwidth=72
        execute('normal gg')
        call search('^$')
      ]]
    },
    { 'go', function()
        u.set_indent(2, true)
      end
    },
    { 'php', function()
        bo.iskeyword = '@,48-57,_,192-255,$'
      end
    },
    { 'markdown', function()
        cmd('setlocal spell spelllang=en_gb')
      end
    },
  }
}

u.augroup('x_autogroups', config_group)
