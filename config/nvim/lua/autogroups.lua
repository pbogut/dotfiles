local U = require('utils')
local b = vim.b
local bo = vim.bo
local cmd = vim.cmd
local fn = vim.fn
local map = vim.api.nvim_set_keymap
local buf_map = vim.api.nvim_buf_set_keymap

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
        U.set_indent(4)
      end
    },
    { 'sh,vue,javascript,vim,lua,yaml,yaml.docker-compose,ruby',
      function()
        U.set_indent(2)
      end
    },
    { 'go', function()
        U.set_indent(2, true)
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
    { 'help', function()
        map('n', 'q', '<c-w>q', { noremap=true })
      end
    },
  }
}

U.augroups('config_group', config_group)
