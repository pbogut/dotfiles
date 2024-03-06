local xdebug = {}
---@type LazyPluginSpec
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    { 'rcarriga/nvim-dap-ui', config = true },
  },
  keys = {
    { '<space>dbc', '<plug>(dap-breakpoint-condition)' },
    { '<space>dbl', '<plug>(dap-breakpoint-log)' },
    { '<space>dd', '<plug>(dap-breakpoint-toggle)' },
    { '<space>dc', '<plug>(dap-continue)' },
    { '<space>ds', '<plug>(dap-close)' },
    { '<space>dl', '<plug>(dap-run-last)' },
    { '<space>dr', '<plug>(dap-repl-toggle)' },
    { '<space>dtc', '<plug>(dap-run-to-cursor)' },
    { '<space>di', '<plug>(dap-step-into)' },
    { '<space>dn', '<plug>(dap-step-over)' },
    { '<space>do', '<plug>(dap-step-out)' },
    { '<space>df', '<plug>(dap-breakpoint-list)' },
    { '<space>dx', '<plug>(dap-xdebug-toggle)' },
    { '<space>x', '<plug>(dap-xdebug-toggle)' },
    { '<space>k', '<plug>(dap-ui-hover)' },
  },
  opts = {
    adapters = {
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
      defaults = {
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
      },
    },
    configs = {
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
    },
  },
  init = function()
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
  end,
  config = function(_, opts)
    ---@type any
    local dap = require('dap')
    local cfg = require('pbogut.config')
    local u = require('pbogut.utils')
    local k = vim.keymap
    local local_config = cfg.get('dap', {})

    dap.adapters = opts.adapters

    local function load_config(lang, conf)
      dap.configurations[lang] = dap.configurations[lang] or {}
      table.insert(dap.configurations[lang], vim.tbl_extend('keep', conf or {}, opts.adapters.defaults[lang]))
    end

    -- get config from config plugin
    for lang, _ in pairs(local_config) do
      for _, c in pairs(local_config[lang]) do
        load_config(lang, c)
      end
    end

    -- if no config for lang get it from local configs
    for lang, _ in pairs(opts.configs) do
      if not dap.configurations[lang] or #dap.configurations[lang] == 0 then
        for _, conf in pairs(opts.configs[lang]) do
          load_config(lang, conf)
        end
      end
    end

    -- if still no config for lang get it from local defaults
    for lang, _ in pairs(opts.adapters.defaults) do
      if not dap.configurations[lang] or #dap.configurations[lang] == 0 then
        dap.configurations[lang] = { opts.adapters.defaults[lang] }
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

    local colors = require('pbogut.settings.colors')
    local i = require('pbogut.settings.icons')

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

    local augroup = vim.api.nvim_create_augroup('x_nvim_dap', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'elixir,eelixir',
      callback = function()
        require('pbogut.plugins.dap.elixir').setup({ defaults = opts.adapters.defaults.elixir })
      end,
    })

    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'dap-repl',
      callback = function()
        vim.cmd.resize(15)
        vim.cmd([[
        inoremap <buffer>        <C-A> <C-O>^
        cnoremap <buffer>        <C-A> <Home>
        inoremap <buffer> <expr> <C-B> getline('.')=~'^\s*$'&&col('.')>strlen(getline('.'))?"0\<Lt>C-D>\<Lt>Esc>kJs":"\<Lt>Left>"
        cnoremap <buffer>        <C-B> <Left>
        inoremap <buffer> <expr> <C-D> col('.')>strlen(getline('.'))?"\<Lt>C-D>":"\<Lt>Del>"
        cnoremap <buffer> <expr> <C-D> getcmdpos()>strlen(getcmdline())?"\<Lt>C-D>":"\<Lt>Del>"
        inoremap <buffer> <expr> <C-E> col('.')>strlen(getline('.'))<bar><bar>pumvisible()?"\<Lt>C-E>":"\<Lt>End>"
        inoremap <buffer> <expr> <C-F> col('.')>strlen(getline('.'))?"\<Lt>C-F>":"\<Lt>Right>"
        cnoremap <buffer> <expr> <C-F> getcmdpos()>strlen(getcmdline())?&cedit:"\<Lt>Right>"
        inoremap <buffer>        <C-n> <Down>
        inoremap <buffer>        <C-p> <Up>

        noremap! <buffer>        <M-b> <S-Left>
        noremap! <buffer>        <M-f> <S-Right>
        noremap! <buffer>        <M-d> <C-O>dw
        cnoremap <buffer>        <M-d> <S-Right><C-W>
        noremap! <buffer>        <M-n> <Down>
        noremap! <buffer>        <M-p> <Up>
        noremap! <buffer>        <M-BS> <C-W>
        noremap! <buffer>        <M-C-h> <C-W>
      ]])
      end,
    })
  end,
}
