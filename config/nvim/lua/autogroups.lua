local u = require('utils')
local b = vim.b
local cmd = vim.cmd
local fn = vim.fn

local config_group = {
  ['BufRead,BufNewFile'] = {
    '*.phtml', function()
      cmd('setfiletype php.phtml')
    end
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
    { 'sql', function()
        b.commentary_format = '-- %s'
      end
    },
    { 'php', function()
        b.commentary_format = '// %s'
      end
    },
    { 'blade', function()
        b.commentary_format = '{{-- %s --}}'
      end
    },
    { 'crontab,nginx,resolv', function()
        b.commentary_format = '# %s'
      end
    },
    { 'php.phtml', function()
        b.commentary_format = '<?php /* %s */ ?>'
      end
    },
    { 'markdown', function()
        cmd('setlocal spell spelllang=en_gb')
      end
    },
  }
}

u.augroup('x_autogroups', config_group)
