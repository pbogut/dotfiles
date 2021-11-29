local u = require'utils'
local lspconfig = require('lspconfig')
local has_lspstatus, lspstatus = pcall(require, 'lsp-status')
local has_lsp_signature, lsp_signature = pcall(require, 'lsp_signature')

local cmd = vim.cmd
local g = vim.g
local no_lsp_bind = '<cmd>lua print("No LSP attached")<CR>'

local signature_action = ''
if has_lsp_signature then
  signature_action = '<cmd>lua require"lsp_signature".toggle_float_win()<CR>'
else
  signature_action = '<cmd>lua vim.lsp.buf.signature_help()<CR>'
end
local bindings = {
  {'n', '<space>er', ':TroubleToggle lsp_references<CR>', no_lsp_bind},
  {'n', ']d', ':lua vim.diagnostic.goto_next()<CR>', no_lsp_bind},
  {'n', '[d', ':lua vim.diagnostic.goto_prev()<CR>', no_lsp_bind},
  {'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', false},
  {'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', false},
  {'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', false},
  {'n', '<C-k>', signature_action, no_lsp_bind},
  {'i', '<C-k>', signature_action, no_lsp_bind},
  {'n', '<space>i', '<cmd>lua vim.lsp.buf.implementation()<CR>', no_lsp_bind},
  {'n', '<space>T', '<cmd>lua vim.lsp.buf.type_definition()<CR>', no_lsp_bind},
  {'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', no_lsp_bind, {silent=false}},
  {'n', '<space>rr', '<cmd>lua vim.lsp.buf.references()<CR>', no_lsp_bind},
  {'n', '<space>ee', '<cmd>lua vim.diagnostic.open_float(0, {scope = "line"})<CR>', no_lsp_bind},
  {'n', '<space>sd', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', no_lsp_bind},
  {'n', '<space>sD', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', no_lsp_bind},
  {'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', no_lsp_bind},
  -- custom format functions with fall back to Neoformat cmd
  {'n', '<space>af', '<cmd>lua vim.lsp.buf.formatting()<CR>', no_lsp_bind},
  {'v', '<space>af', ':lua vim.lsp.buf.range_formatting()<CR>', no_lsp_bind},
  {'x', '<space>af', ':lua vim.lsp.buf.range_formatting()<CR>', no_lsp_bind},
}

-- prevent stupid errors when using mapping with no lsp attached
for _, def in pairs(bindings) do
  if def[4] then
    u.map(def[1], def[2], def[4])
  end
end

local on_attach = function(client, bufnr)
  if has_lsp_signature then
    lsp_signature.on_attach({
      bind = true,
      doc_lines = 10,
      floating_window = true,
      floating_window_above_cur_line = true,
      hint_enable = false,
      handler_opts = { border = "none" },
      toggle_key = '<c-k>'
    })
  end

  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  if has_lspstatus then
    lspstatus.on_attach(client, bufnr)
  end

  -- Mappings.
  for _, def in pairs(bindings) do
    local opts = def[5] or {}
    u.buf_map(bufnr, def[1], def[2], def[3], opts)
  end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
if has_lspstatus then
  capabilities = vim.tbl_extend('keep', capabilities or {}, lspstatus.capabilities)
  lspstatus.register_progress()
end

local function location_handler(_, result, ctx)
  vim.g.lsp_last_word = vim.fn.expand('<cword>')
  if result == nil or vim.tbl_isempty(result) then
    print(ctx.method, 'No location found')
    return nil
  end
  local util = require('vim.lsp.util')
  if vim.tbl_islist(result) then
    if #result == 1 then
      util.jump_to_location(result[1])
    elseif #result > 1 then
      vim.fn.setqflist(util.locations_to_items(result))
      require('plugins.fzf').quickfix(vim.fn.expand('<cword>'));
      -- api.nvim_command("copen")
      -- api.nvim_command("wincmd p")
    end
  else
    util.jump_to_location(result)
  end
end

vim.lsp.handlers['textDocument/declaration'] = location_handler
vim.lsp.handlers['textDocument/definition'] = location_handler
vim.lsp.handlers['textDocument/typeDefinition'] = location_handler
vim.lsp.handlers['textDocument/implementation'] = location_handler
vim.lsp.handlers['textDocument/references'] = function(_, result)
  vim.g.lsp_last_word = vim.fn.expand('<cword>')
  if not result then return end
  if #result == 0 then
    cmd('echo "Getting references..."')
    return
  end
  cmd('echo ""')
  local util = require('vim.lsp.util')
  vim.fn.setqflist(util.locations_to_items(result))
  require('plugins.fzf').quickfix(vim.fn.expand('<cword>'));
  -- api.nvim_command("copen")
  -- api.nvim_command("wincmd p")
end

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    -- Enable underline, use default values
    underline = true,
    -- Enable virtual text, override spacing to 8
    virtual_text = {
      spacing = 4,
      prefix = '■',
    },
    -- Disable a feature
    update_in_insert = false,
  }
)

u.highlights({
  FloatBorder = { guibg = g.colors.base0, guifg = vim.g.colors.base03 },
  DiagnosticFloatingInfo = { guibg = '#a68f46', guifg = '#073642' },
  DiagnosticFloatingHint = { guibg = '#9eab7d', guifg = '#073642' },
  DiagnosticFloatingError = { guibg = '#dc322f', guifg = '#073642' },
  DiagnosticFloatingWarning = { guibg = '#d33682', guifg = '#073642' },
  DiagnosticSignError = { guibg = '#073642', guifg = '#dc322f' },
  DiagnosticSignWarn = { guibg = '#073642', guifg = '#d33682' },
  DiagnosticSignInfo = { guibg = '#073642', guifg = '#a68f46' },
  DiagnosticSignHint = { guibg = '#073642', guifg = '#9eab7d' },
  DiagnosticVirtualTextError = { guifg = '#dc322f' },
  DiagnosticVirtualTextWarning = { guifg = '#d33682' },
  DiagnosticVirtualTextInfo = { guifg = '#a68f46' },
  DiagnosticVirtualTextHint = { guifg = '#9eab7d' },
  LspSignatureActiveParameter = { link = 'Search' },
})

u.signs({
  DiagnosticSignError = { text = g.icon.error, texthl = "DiagnosticSignError" },
  DiagnosticSignWarn = { text = g.icon.warning, texthl = "DiagnosticSignWarn" },
  DiagnosticSignInfo = { text = g.icon.info, texthl = "DiagnosticSignInfo" },
  DiagnosticSignHint = { text = g.icon.hint, texthl = "DiagnosticSignHint" },
})

lspconfig.vimls.setup {on_attach = on_attach}
lspconfig.vuels.setup {on_attach = on_attach}
lspconfig.bashls.setup {on_attach = on_attach}
lspconfig.gopls.setup {on_attach = on_attach}
lspconfig.cssls.setup {on_attach = on_attach, capabilities = capabilities}
-- lspconfig.pyright.setup {on_attach = on_attach}
lspconfig.jedi_language_server.setup {on_attach = on_attach}
lspconfig.dockerls.setup {on_attach = on_attach}
lspconfig.solargraph.setup {on_attach = on_attach}
-- require 'plugins.lsp.denols'.setup {on_attach = on_attach}
require 'plugins.lsp.tsserver'.setup{on_attach = on_attach}
require 'plugins.lsp.emmet_ls'.setup {on_attach = on_attach, capabilities = capabilities}
require 'plugins.lsp.tailwindcss'.setup {on_attach = on_attach, capabilities = capabilities}
require 'plugins.lsp.sumneko_lua'.setup {on_attach = on_attach, capabilities = capabilities}
require 'plugins.lsp.intelephense'.setup {on_attach = on_attach, capabilities = capabilities}
require 'plugins.lsp.jsonls'.setup {on_attach = on_attach, capabilities = capabilities}
require 'plugins.lsp.html'.setup {on_attach = on_attach, capabilities = capabilities}
require 'plugins.lsp.elixirls'.setup {on_attach = on_attach, capabilities = capabilities}

local function get_active_client_map()
  local client_list = {}
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    local root_dir = client.config.root_dir
    local filetypes = client.config.filetypes
    local client_id = client.id
    for _, file_type  in ipairs(filetypes) do
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
  cmd(':w')
  -- then reload so lsp is attached when reloaded from actuall file
  cmd(':edit')
end

u.command('LspReload', function()
     vim.lsp.stop_client(vim.lsp.get_active_clients())
     cmd('edit')
end)
u.command('LspAttachBuffer', attach_lsp_to_new_buffer)

return {
  on_attach = on_attach
}
