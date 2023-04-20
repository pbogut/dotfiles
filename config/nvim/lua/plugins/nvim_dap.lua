local cfg = require('config')
local u = require('utils')
local k = vim.keymap
local i = vim.g.icon
local colors = vim.g.colors

local adapters = {
  php = {
    type = 'executable',
    command = mason_bin('php-debug-adapter'),
    args = {},
  },
  mix_task = {
    type = 'executable',
    command = mason_bin('elixir-ls-debugger'),
    args = {},
  },
  chrome = {
    type = 'executable',
    command = mason_bin('chrome-debug-adapter'),
    args = {},
  },
}

local defaults = {
  php = {
    before = function()
      vim.cmd([[ let $XDEBUG_TRIGGER=1 ]])
      vim.notify('Xdebug enabled')
    end,
    log = true,
    type = 'php',
    request = 'launch',
    name = 'Xdebug',
    port = 9003,
  },
  elixir = {
    type = 'mix_task',
    name = 'mix test',
    task = 'test',
    request = 'launch',
    projectDir = '${workspaceFolder}',
    requireFiles = {
      'test/**/test_helper.exs',
      'test/**/*_test.exs',
    },
    excludeModules = {
      'Bcrypt',
    },
  },
}

local configs = {
  elixir = {
    {
      task = 'test',
      name = 'test',
      taskArgs = { '--trace' },
    },
    {
      task = 'test',
      name = 'test (phx)',
      taskArgs = { '--trace' },
      startApps = true,
    },
    {
      name = 'phx.server',
      task = 'phx.server',
      startApps = true,
    },
  },
}

local function config()
  local dap = require('dap')
  local local_config = cfg.get('dap', {})

  dap.adapters = adapters

  local function load_config(lang, conf)
    dap.configurations[lang] = dap.configurations[lang] or {}
    table.insert(dap.configurations[lang], vim.tbl_extend('keep', conf or {}, defaults[lang]))
  end

  -- get config from config plugin
  for lang, _ in pairs(local_config) do
    for _, c in pairs(local_config[lang]) do
      load_config(lang, c)
    end
  end

  -- if no config for lang get it from local configs
  for lang, _ in pairs(configs) do
    if not dap.configurations[lang] or #dap.configurations[lang] == 0 then
      for _, conf in pairs(configs[lang]) do
        load_config(lang, conf)
      end
    end
  end

  -- if still no config for lang get it from local defaults
  for lang, _ in pairs(defaults) do
    if not dap.configurations[lang] or #dap.configurations[lang] == 0 then
      dap.configurations[lang] = { defaults[lang] }
    end
  end

  k.set('n', '<space>dbc', function()
    dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
  end)
  k.set('n', '<space>dbl', function()
    dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
  end)
  k.set('n', '<space>dd', dap.toggle_breakpoint)
  k.set('n', '<space>dc', dap.continue)
  k.set('n', '<space>ds', dap.close)
  k.set('n', '<space>dl', function()
    dap.run_last()
  end)
  k.set('n', '<space>dr', dap.repl.toggle)
  k.set('n', '<space>dtc', dap.run_to_cursor)
  k.set('n', '<space>di', dap.step_into)
  k.set('n', '<space>dn', dap.step_over)
  k.set('n', '<space>do', dap.step_out)
  k.set('n', '<space>df', function()
    dap.list_breakpoints()
    if vim.fn.exists(':Trouble') > 0 then
      vim.cmd.Trouble('quickfix')
    else
      vim.cmd.copen()
    end
  end)
  k.set('n', '<space>dx', function()
    vim.cmd([[
      if $XDEBUG_TRIGGER == 1
        unlet $XDEBUG_TRIGGER
        lua vim.notify('Xdebug disabled')
      else
        let $XDEBUG_TRIGGER=1
        lua vim.notify('Xdebug enabled')
      endif
    ]])
  end)

  u.highlights({
    DapBreakpoint = { link = 'DiagnosticSignError' },
    DapBreakpointCondition = { link = 'DiagnosticSignWarn' },
    DapBreakpointRejected = { guifg = colors.orange, guibg = colors.base02 },
    DapLogPoint = { link = 'DiagnosticSignInfo' },
    DapStopped = { guifg = '#719e07', guibg = colors.base02 },
  })

  u.signs({
    DapBreakpoint = { text = i.breakpoint, texthl = 'DapBreakpoint' },
    DapBreakpointCondition = { text = i.breakpoint_condition, texthl = 'DapBreakpointCondition' },
    DapBreakpointRejected = { text = i.breakpoint_rejected, texthl = 'DapBreakpointRejected' },
    DapLogPoint = { text = i.breakpoint_info, texthl = 'DapLogPoint' },
    DapStopped = { text = i.breakpoint_current, texthl = 'DapStopped' },
  })

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('x_nvim_dap', { clear = true }),
    pattern = 'elixir,eelixir',
    callback = function()
      require('plugins.dap.elixir').setup({ defaults = defaults.elixir })
    end,
  })
end

return {
  config = config,
}
