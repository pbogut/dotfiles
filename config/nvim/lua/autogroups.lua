local config = require('config')
local u = require('utils')
local bo = vim.bo
local b = vim.b
local wo = vim.wo
local w = vim.w
local cmd = vim.cmd
local fn = vim.fn

local config_group = {
  -- fix alacritty startup resize bug
  VimEnter = {
    '*',
    ':silent exec "!kill -s SIGWINCH $PPID"',
  },
  -- fix terminal display
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
        cmd([[
          setlocal spell spelllang=en_gb
        ]])
      end,
    },
    {
      'mail',
      function()
        cmd([[
          setlocal spell spelllang=en_gb
          setlocal textwidth=72
          execute('normal gg')
          call search('^$')
        ]])
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

-- Auto format on save
if config.get('autoformat_on_save.enabled') then
  u.augroup('x_autoformat', {
    BufWritePre = {
      {
        '*',
        function()
          local file = vim.fn.expand('%:p')
          local cwd = vim.fn.getcwd()
          if file:match('^' .. cwd) then
            vim.lsp.buf.formatting()
          end
        end,
      },
    },
  })
end
