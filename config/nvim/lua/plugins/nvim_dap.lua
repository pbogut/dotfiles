local cfg = require('config')
local u = require('utils')
local i = vim.g.icon
local c = vim.g.colors

local function config()
  local dap = require('dap')
  local phpDebugJs = vim.fn.stdpath('data') ..
        '/site/pack/packer/start/vscode-php-debug/out/phpDebug.js'

  dap.configurations.php = {}
  dap.adapters.php = {
    type = 'executable',
    command = 'node',
    args = { phpDebugJs }
  }

  local local_config = cfg.get('dap', {})
  local defaults = { php = {} }
  defaults.php = {
    log = true,
    type = 'php',
    request = 'launch',
    name = 'Xdebug',
    port = 9003
  }

  for lang, configs in pairs(local_config) do
    for _, c in pairs(configs) do
      dap.configurations[lang] = dap.configurations[lang] or {}
      table.insert(
        dap.configurations[lang],
        vim.tbl_extend('keep', c or {}, defaults[lang])
      )
    end
  end

  for lang, _ in pairs(defaults) do
    if #dap.configurations[lang] == 0 then
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
    DapBreakpointRejected = { guifg = c.orange, guibg = c.base02 },
    DapLogPoint = { link = 'DiagnosticSignInfo' },
    DapStopped = { guifg = '#719e07', guibg = c.base02 },
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
