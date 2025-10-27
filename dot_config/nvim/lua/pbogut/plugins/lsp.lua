---@type LazyPluginSpec
return {
  enabled = true,
  'neovim/nvim-lspconfig',
  event = 'BufReadPre',
  dependencies = {
    { 'ray-x/lsp_signature.nvim', cond = true },
    { 'smiteshp/nvim-navic', cond = true },
  },
  init = function() end,
  config = function()
    local command = vim.api.nvim_create_user_command
    local u = require('pbogut.utils')
    local lspconfig = require('lspconfig')
    local has_lspstatus, lspstatus = pcall(require, 'lsp-status')
    local has_lsp_signature, lsp_signature = pcall(require, 'lsp_signature')

    local b = {}

    vim.diagnostic.config({
      severity_sort = true,
      float = {
        source = 'always',
      },
      virtual_text = {
        spacing = 4,
        prefix = '■',
      },
      signs = {
        priority = 5, -- so dap signs are visible on error lines (dap defaults to 11)
      },
    })

    local lsp_config = require('pbogut.plugins.lsp.config')
    local on_attach = lsp_config.on_attach
    local servers = lsp_config.servers

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    if has_lspstatus then
      capabilities = vim.tbl_extend('keep', capabilities or {}, lspstatus.capabilities)
      lspstatus.register_progress()
    end

    u.highlights({
      DiagnosticFloatingInfo = { guibg = vim.c.ad_info, guifg = vim.c.base02 },
      DiagnosticFloatingHint = { guibg = vim.c.ad_hint, guifg = vim.c.base02 },
      DiagnosticFloatingError = { guibg = vim.c.red, guifg = vim.c.base02 },
      DiagnosticFloatingWarning = { guibg = vim.c.magenta, guifg = vim.c.base02 },
      DiagnosticSignError = { guibg = vim.c.sign_col_bg, guifg = vim.c.red },
      DiagnosticSignWarn = { guibg = vim.c.sign_col_bg, guifg = vim.c.magenta },
      DiagnosticSignInfo = { guibg = vim.c.sign_col_bg, guifg = vim.c.ad_info },
      DiagnosticSignHint = { guibg = vim.c.sign_col_bg, guifg = vim.c.ad_hint },
      DiagnosticVirtualTextError = { guifg = vim.c.red },
      DiagnosticVirtualTextWarning = { guifg = vim.c.magenta },
      DiagnosticVirtualTextInfo = { guifg = vim.c.ad_info },
      DiagnosticVirtualTextHint = { guifg = vim.c.ad_hint },
      LspSignatureActiveParameter = { link = 'Search' },
    })

    local icons = require('pbogut.settings.icons')
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = icons.error,
          [vim.diagnostic.severity.WARN] = icons.warning,
          [vim.diagnostic.severity.INFO] = icons.info,
          [vim.diagnostic.severity.HINT] = icons.hint,
        },
      },
    })

    for _, server in ipairs(servers) do
      local opts = {}
      local has_config, my_config = pcall(require, 'pbogut.plugins.lsp.' .. server.name)
      if has_config then
        opts = my_config
      end
      opts.on_attach = on_attach
      if server.snippet_support then
        opts.capabilities = capabilities
      end
      vim.lsp.config(server.name, opts)
      vim.lsp.enable(server.name)
    end

    local function get_active_client_map()
      local client_list = {}
      for _, client in ipairs(vim.lsp.get_clients()) do
        local root_dir = client.config.root_dir
        local filetypes = client.config.filetypes
        local client_id = client.id
        for _, file_type in ipairs(filetypes) do
          if nil == client_list[file_type] then
            client_list[file_type] = {}
          end
          client_list[file_type][root_dir] = client_id
        end
      end

      return client_list
    end

    local function attach_lsp_to_new_buffer()
      local clients = get_active_client_map()
      local bufnr = vim.api.nvim_get_current_buf()
      local file_type = vim.api.nvim_buf_get_option(bufnr, 'filetype')
      local file_name = vim.api.nvim_buf_get_name(bufnr)
      if clients[file_type] then
        for root_dir, client_id in pairs(clients[file_type]) do
          local pos, _ = file_name:find('^' .. root_dir)
          if pos == 1 then
            vim.lsp.buf_attach_client(bufnr, client_id)
          end
        end
      end
      -- write to not lose any changes
      vim.cmd.write()
      -- then reload so lsp is attached when reloaded from actuall file
      vim.cmd.edit()
    end

    local function update_diagnostics_visibility(visible)
      if visible then
        vim.diagnostic.config({
          underline = true,
          virtual_text = true,
        })
      else
        vim.diagnostic.config({
          underline = false,
          virtual_text = false,
        })
      end
    end

    command('LspReload', function(_)
      vim.lsp.stop_client(vim.lsp.buf_get_clients())
      vim.cmd.edit()
    end, {})
    command('LspAttachBuffer', attach_lsp_to_new_buffer, {})
    command('DiagnosticsBufferToggle', function(_)
      vim.b.diagnostic_hide = vim.b.diagnostic_hide ~= true
      update_diagnostics_visibility(vim.b.diagnostic_hide ~= true)
    end, {})
    command('DiagnosticsBufferHide', function(_)
      vim.b.diagnostic_hide = true
      update_diagnostics_visibility(false)
    end, {})
    command('DiagnosticsBufferShow', function(_)
      vim.b.diagnostic_hide = false
      update_diagnostics_visibility(true)
    end, {})

    local augroup = vim.api.nvim_create_augroup('x_lsp', { clear = true })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = augroup,
      pattern = '*',
      callback = function()
        update_diagnostics_visibility(vim.b.diagnostic_hide ~= true)
      end,
    })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = augroup,
      pattern = '*.rs',
      callback = function()
        if #vim.lsp.buf_get_clients() > 0 then
          lsp_config.lsp_formatting(vim.fn.bufnr())
        end
      end,
    })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = augroup,
      pattern = '*',
      callback = function()
        local config = require('pbogut.config')
        if config.get('lsp.autoformat_on_save.enabled') then
          local file_types = config.get('lsp.autoformat_on_save.file_types', {})
          local file = vim.fn.expand('%:p')
          local cwd = vim.fn.getcwd()
          local ft = vim.bo.filetype

          local for_filetype = #file_types == 0
          for lang, on in pairs(file_types) do
            for_filetype = lang == ft and on
          end

          if file:sub(1, #cwd) == cwd and for_filetype then
            if #vim.lsp.buf_get_clients() > 0 then
              lsp_config.lsp_formatting(vim.fn.bufnr())
            else
              vim.cmd('normal! migg=G`i')
            end
          end
        end
      end,
    })
  end,
}
