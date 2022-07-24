local u = require('utils')
local bo = vim.bo
local wo = vim.wo
local cmd = vim.cmd

local config_group = {
  TextYankPost = {
    {
      '*',
      function()
        require('vim.highlight').on_yank({ timeout = 75, higroup = 'Search' })
      end,
    },
  },
  TermOpen = {
    {
      '*',
      function()
        wo.number = false
        wo.relativenumber = false
        wo.signcolumn = 'no'
        wo.cursorline = false
        wo.cursorcolumn = false
      end,
    },
  },
  BufEnter = {
    {
      'env.*',
      function()
        bo.filetype = 'sh'
      end,
    },
    {
      'crontab.*',
      function()
        bo.commentstring = '# %s'
      end,
    },
    {
      '*.phtml',
      function()
        bo.filetype = 'html'
        bo.syntax = 'php'
      end,
    },
  },
  FileType = {
    {
      'html,css,scss,xml,java,elixir,eelixir,c,php,php.phtml,sql,blade,elm',
      function()
        u.set_indent(4)
      end,
    },
    {
      'sh,vue,javascript,vim,lua,yaml,yaml.docker-compose,ruby',
      function()
        u.set_indent(2)
      end,
    },
    {
      'NeogitCommitMessage',
      function()
        cmd('setlocal spell spelllang=en_gb')
      end,
    },
    {
      'mail',
      function()
        cmd('setlocal spell spelllang=en_gb')
        vim.bo.textwidth = 72
        vim.fn.execute('normal gg')
        vim.fn.search('^$')
      end,
    },
    {
      'make',
      function()
        u.set_indent(4, true)
      end,
    },
    {
      'go',
      function()
        u.set_indent(2, true)
      end,
    },
    {
      'javascript',
      function()
        bo.iskeyword = '@,48-57,_,192-255' -- remove $ from keyword list, whiy tist there in js anyway?
      end,
    },
    {
      'markdown',
      function()
        cmd('setlocal spell spelllang=en_gb')
      end,
    },
  },
}

u.augroup('x_autogroups', config_group)

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  callback = function()
    local pid, WINCH = vim.fn.getpid(), vim.loop.constants.SIGWINCH
    vim.defer_fn(function()
      vim.loop.kill(pid, WINCH)
    end, 20)
  end,
})
