local cfg = require('config')
local u = require('utils')
local k = vim.keymap
local i = vim.g.icon
local colors = vim.g.colors
local xdebug = {}

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
      xdebug.enable()
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
  javascript = {
    type = 'chrome',
    name = 'qbwork',
    request = 'attach',
    program = '${file}',
    cwd = vim.fn.getcwd(),
    sourceMaps = true,
    protocol = 'inspector',
    port = 9224,
    webRoot = '${workspaceFolder}',
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

  k.set('n', '<plug>(dap-breakpoint-condition)', function()
    dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
  end)
  k.set('n', '<plug>(dap-breakpoint-log)', function()
    dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
  end)
  k.set('n', '<plug>(dap-breakpoint-toggle)', dap.toggle_breakpoint)
  k.set('n', '<plug>(dap-continue)', dap.continue)
  k.set('n', '<plug>(dap-close)', dap.close)
  k.set('n', '<plug>(dap-run-last)', function()
    dap.run_last()
  end)
  k.set('n', '<plug>(dap-repl-toggle)', dap.repl.toggle)
  k.set('n', '<plug>(dap-run-to-cursor)', dap.run_to_cursor)
  k.set('n', '<plug>(dap-step-into)', dap.step_into)
  k.set('n', '<plug>(dap-step-over)', dap.step_over)
  k.set('n', '<plug>(dap-step-out)', dap.step_out)
  k.set('n', '<plug>(dap-breakpoint-list)', function()
    dap.list_breakpoints()
    if vim.fn.exists(':Trouble') > 0 then
      vim.cmd.Trouble('quickfix')
    else
      vim.cmd.copen()
    end
  end)
  k.set('n', '<plug>(dap-xdebug-toggle)', function()
    xdebug.toggle()
  end)
  k.set('n', '<plug>(dap-ui-hover)', function()
    local has_dapui, dapui = pcall(require, 'dapui')
    if has_dapui then
      dapui.eval()
    else
      vim.notify('dap-ui is not installed', vim.log.levels.WARN, { title = 'dap' })
    end
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

function xdebug.enable()
  if not xdebug.enabled then
    vim.cmd.Lazy('load vim-test')
    vim.g['test#php#phpunit#executable_orig'] = vim.fn['test#php#phpunit#executable']()
    vim.g['test#php#phpunit#executable'] = 'env XDEBUG_TRIGGER=1 ' .. vim.g['test#php#phpunit#executable_orig']
    xdebug.enabled = true
  end
  vim.notify('Xdebug enabled')
end

function xdebug.disable()
  if xdebug.enabled then
    vim.cmd.Lazy('load vim-test')
    vim.g['test#php#phpunit#executable'] = vim.g['test#php#phpunit#executable_orig']
    vim.g['test#php#phpunit#executable_orig'] = nil
    xdebug.enabled = false
  end
  vim.notify('Xdebug disabled')
end

function xdebug.toggle()
  if xdebug.enabled then
    xdebug.disable()
  else
    xdebug.enable()
  end
end

return {
  config = config,
}
