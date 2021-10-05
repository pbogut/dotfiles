local u = require'utils'
local lspconfig = require('lspconfig')
local has_lspstatus, lspstatus = pcall(require, 'lsp-status')

local cmd = vim.cmd
local g = vim.g
local no_lsp_bind = '<cmd>lua print("No LSP attached")<CR>'
local format_bind = '<cmd>Neoformat<CR>'

local bindings = {
  {'n', ']d', ':lua vim.diagnostic.goto_next()<CR>', no_lsp_bind},
  {'n', '[d', ':lua vim.diagnostic.goto_prev()<CR>', no_lsp_bind},
  {'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', false},
  {'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', false},
  {'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', false},
  {'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', no_lsp_bind},
  {'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', no_lsp_bind},
  {'n', '<space>i', '<cmd>lua vim.lsp.buf.implementation()<CR>', no_lsp_bind},
  {'n', '<space>T', '<cmd>lua vim.lsp.buf.type_definition()<CR>', no_lsp_bind},
  {'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', no_lsp_bind, {silent=false}},
  {'n', '<space>rr', '<cmd>lua vim.lsp.buf.references()<CR>', no_lsp_bind},
  {'n', '<space>ee', '<cmd>lua vim.diagnostic.show_line_diagnostics()<CR>', no_lsp_bind},
  {'n', '<space>sd', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', no_lsp_bind},
  {'n', '<space>sD', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', no_lsp_bind},
  {'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', no_lsp_bind},
  -- custom format functions with fall back to Neoformat cmd
  {'n', '<space>af', '<cmd>lua vim.lsp.buf.x_formatting()<CR>', format_bind},
  {'v', '<space>af', ':lua vim.lsp.buf.x_range_formatting()<CR>', format_bind},
  {'x', '<space>af', ':lua vim.lsp.buf.x_range_formatting()<CR>', format_bind},
}

-- prevent stupid errors when using mapping with no lsp attached
for _, def in pairs(bindings) do
  if def[4] then
    u.map(def[1], def[2], def[4])
  end
end

local on_attach = function(client, bufnr)
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
  DiagnosticFloatingInformation = { guibg = '#a68f46', guifg = '#073642' },
  DiagnosticFloatingHint = { guibg = '#9eab7d', guifg = '#073642' },
  DiagnosticFloatingError = { guibg = '#dc322f', guifg = '#073642' },
  DiagnosticFloatingWarning = { guibg = '#d33682', guifg = '#073642' },
  DiagnosticSignError = { guibg = '#073642', guifg = '#dc322f' },
  DiagnosticSignWarn = { guibg = '#073642', guifg = '#d33682' },
  DiagnosticSignInfo = { guibg = '#073642', guifg = '#a68f46' },
  DiagnosticSignHint = { guibg = '#073642', guifg = '#9eab7d' },
  DiagnosticVirtualTextError = { guifg = '#dc322f' },
  DiagnosticVirtualTextWarning = { guifg = '#d33682' },
  DiagnosticVirtualTextInformation = { guifg = '#a68f46' },
  DiagnosticVirtualTextHint = { guifg = '#9eab7d' },
})

u.signs({
  DiagnosticSignError = { text = g.icon.error, texthl = "DiagnosticSignError" },
  DiagnosticSignWarn = { text = g.icon.warning, texthl = "DiagnosticSignWarning" },
  DiagnosticSignInfo = { text = g.icon.info, texthl = "DiagnosticSignInformation" },
  DiagnosticSignHint = { text = g.icon.hint, texthl = "DiagnosticSignHint" },
})

-- npm install -g vim-language-server
lspconfig.vimls.setup {on_attach = on_attach}
-- npm install -g vls
lspconfig.vuels.setup {on_attach = on_attach}
-- npm install -g bash-language-server
lspconfig.bashls.setup {on_attach = on_attach}
-- GO111MODULE=on go get golang.org/x/tools/gopls@latest
lspconfig.gopls.setup {on_attach = on_attach}
-- npm install -g vscode-css-languageserver-bin
lspconfig.cssls.setup {on_attach = on_attach, capabilities = capabilities}
-- npm install -g pyright
lspconfig.pyright.setup {on_attach = on_attach}
-- pacman -S deno
lspconfig.denols.setup {on_attach = on_attach}
-- npm install -g @tailwindcss/language-server
require 'plugins.lsp.tailwindcss'.setup {on_attach = on_attach, capabilities = capabilities}
-- see https://github.com/sumneko/lua-language-server/wiki/Build-and-Run-(Standalone)
require 'plugins.lsp.sumneko_lua'.setup {on_attach = on_attach, capabilities = capabilities}
-- npm install -g intelephense
require 'plugins.lsp.intelephense'.setup {on_attach = on_attach, capabilities = capabilities}
-- npm install -g vscode-json-languageserver
require 'plugins.lsp.jsonls'.setup(on_attach)
-- npm install -g vscode-html-languageserver-bin
require 'plugins.lsp.html'.setup {on_attach = on_attach, capabilities = capabilities}
-- curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls.zip
-- unzip elixir-ls.zip -d $HOME/.elixir_ls/elixir-ls
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

-- global
function vim.lsp.buf.x_range_formatting()
  local _, formatted = pcall(vim.lsp.buf.range_formatting)
  if not formatted then
    cmd("'<,'>Neoformat")
    print('File formated with Neoformat')
  else
    print('Range formated with LSP')
  end
end

-- global
function vim.lsp.buf.x_formatting()
  local _, formatted = pcall(vim.lsp.buf.formatting)
  if not formatted then
    cmd('Neoformat')
    print('File formated with Neoformat')
  else
    print('File formated with LSP')
  end
end

u.command('LspReload', function()
     vim.lsp.stop_client(vim.lsp.get_active_clients())
     cmd('edit')
end)
u.command('LspAttachBuffer', attach_lsp_to_new_buffer)
-- u.augroup('x_nvim_lsp', {
--     BufNewFile = {
--       { "*", attach_lsp_to_new_buffer }
--     }
-- })
