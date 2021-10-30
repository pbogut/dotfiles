local cfg = require('config')
local u = require('utils')
local i = vim.g.icon
local colors = vim.g.colors

local adapters = {
  php = {
    type = 'executable',
    command = 'node',
    args = {
      plugin_path('vscode-php-debug/out/phpDebug.js')
    }
  },
  mix_task = {
    type = 'executable',
    command = plugin_path('elixir-ls/out/debugger.sh'),
    args = {}
  }
}

local defaults = {
  php = {
    log = true,
    type = 'php',
    request = 'launch',
    name = 'Xdebug',
    port = 9003
  },
  elixir = {
    type = "mix_task",
    name = "mix test",
    task = "test",
    request = "launch",
    projectDir = "${workspaceFolder}",
    requireFiles = {
      "test/**/test_helper.exs",
      "test/**/*_test.exs"
    },
    excludeModules = {
      "Bcrypt"
    }
  }
}

local configs = {
  elixir = {
    {
      task = "test",
      name = "test",
      taskArgs = {"--trace"},
    },
    {
      task = "test",
      name = "test (phx)",
      taskArgs = {"--trace"},
      startApps = true,
    },
    {
      name = "phx.server",
      task = "phx.server",
      startApps = true,
    }
  }
}

local function config()
  local dap = require('dap')
  local local_config = cfg.get('dap', {})

  dap.adapters = adapters

  local function load_config(lang, conf)
    dap.configurations[lang] = dap.configurations[lang] or {}
    table.insert(
      dap.configurations[lang],
      vim.tbl_extend('keep', conf or {}, defaults[lang])
    )
  end

  -- get config from .nvim-config.json
  for lang, _ in pairs(local_config) do
    for _, c in pairs(local_config[lang]) do
      load_config(lang, c)
    end
  end

  -- if no config for lang get it from local configs
  for lang, _ in pairs(configs) do
    if not dap.configurations[lang]
      or #dap.configurations[lang] == 0
    then
      for _, conf in pairs(configs[lang]) do
        load_config(lang, conf)
      end
    end
  end

  -- if still no config for lang get it from local defaults
  for lang, _ in pairs(defaults) do
    if not dap.configurations[lang]
      or #dap.configurations[lang] == 0
    then
      dap.configurations[lang] = { defaults[lang] }
    end
  end

  u.map('n', '<space>dbc', function()
    dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
  end)
  u.map('n', '<space>dbl', function()
    dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
  end)
  u.map('n', '<space>dd', dap.toggle_breakpoint)
  u.map('n', '<space>dc', dap.continue)
  u.map('n', '<space>ds', dap.close)
  u.map('n', '<space>dl', function() dap.run_last() end)
  u.map('n', '<space>dr', dap.repl.toggle)
  u.map('n', '<space>dtc', dap.run_to_cursor)
  u.map('n', '<space>di', dap.step_into)
  u.map('n', '<space>dn', dap.step_over)
  u.map('n', '<space>do', dap.step_out)
  u.map('n', '<space>df', function()
    dap.list_breakpoints()
    require('plugins.fzf').quickfix()
  end)

  u.highlights({
    DapBreakpoint = { link = 'DiagnosticSignError' },
    DapBreakpointCondition = { link = 'DiagnosticSignWarn' },
    DapBreakpointRejected = { guifg = colors.orange, guibg = colors.base02 },
    DapLogPoint = { link = 'DiagnosticSignInfo' },
    DapStopped = { guifg = '#719e07', guibg = colors.base02 },
  })

  u.signs({
    DapBreakpoint = { text = i.breakpoint, texthl = "DapBreakpoint" },
    DapBreakpointCondition = { text = i.breakpoint_condition, texthl = "DapBreakpointCondition" },
    DapBreakpointRejected = { text = i.breakpoint_rejected, texthl = "DapBreakpointRejected" },
    DapLogPoint = { text = i.breakpoint_info, texthl = "DapLogPoint" },
    DapStopped = { text = i.breakpoint_current, texthl = "DapStopped" },
  })
end

return {
  config = config
}
