local u = require'utils'
local lspconfig = require('lspconfig')
local cmd = vim.cmd

local no_lsp_bind = '<cmd>lua print("No LSP attached")<CR>'
local format_bind = '<cmd>Neoformat<CR>'

local bindings = {
  { 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', false },
  { 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', false },
  { 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', false },
  { 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', no_lsp_bind },
  { 'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', no_lsp_bind },
  { 'n', '<space>i', '<cmd>lua vim.lsp.buf.implementation()<CR>', no_lsp_bind },
  { 'n', '<space>T', '<cmd>lua vim.lsp.buf.type_definition()<CR>', no_lsp_bind },
  { 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', no_lsp_bind },
  { 'n', '<space>rr', '<cmd>lua vim.lsp.buf.references()<CR>', no_lsp_bind },
  { 'n', '<space>d', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', no_lsp_bind },
  { 'n', '<space>sd', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', no_lsp_bind },
  { 'n', '<space>sD', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', no_lsp_bind },
  { 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', no_lsp_bind },
  -- custom format functions with fall back to Neoformat cmd
  { 'n', '<space>af', '<cmd>lua vim_lsp_buf_formatting()<CR>', format_bind },
  { 'v', '<space>af', ':lua vim_lsp_buf_range_formatting()<CR>', format_bind },
  { 'x', '<space>af', ':lua vim_lsp_buf_range_formatting()<CR>', format_bind },
}

-- prevent stupid errors when using mapping with no lsp attached
for _, def in pairs(bindings) do
  if def[4] then
    u.map(def[1], def[2], def[4])
  end
end

local on_attach = function(_, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  require'completion'.on_attach()

  -- Mappings.
  for _, def in pairs(bindings) do
    u.buf_map(bufnr, def[1], def[2], def[3])
  end
end

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    -- Enable underline, use default values
    underline = true,
    -- Enable virtual text, override spacing to 8
    virtual_text = {
      spacing = 8,
      prefix = '■',
    },
    -- Disable a feature
    update_in_insert = false,
  }
)

-- npm install -g vim-language-server
lspconfig.vimls.setup { on_attach = on_attach }
-- npm install -g vls
lspconfig.vuels.setup { on_attach = on_attach }
-- npm install -g bash-language-server
lspconfig.bashls.setup { on_attach = on_attach }
-- GO111MODULE=on go get golang.org/x/tools/gopls@latest
lspconfig.gopls.setup { on_attach = on_attach }
-- npm install -g typescript-language-server
lspconfig.tsserver.setup { on_attach = on_attach }
-- npm install -g pyright
lspconfig.pyright.setup { on_attach = on_attach }
-- see https://github.com/sumneko/lua-language-server/wiki/Build-and-Run-(Standalone)
require 'plugins.lsp.sumneko_lua'.setup(on_attach)
-- see ./lsp/pyls_ms.lua
require 'plugins.lsp.pyls_ms'.setup(on_attach)
-- npm install -g intelephense
require 'plugins.lsp.intelephense'.setup(on_attach)
-- npm install -g vscode-json-languageserver
require 'plugins.lsp.jsonls'.setup(on_attach)
-- npm install -g vscode-html-languageserver-bin
require 'plugins.lsp.html'.setup(on_attach)
-- npm install -g vscode-css-languageserver-bin
require 'plugins.lsp.cssls'.setup(on_attach)

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

function attach_lsp_to_new_buffer()
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
end

function vim_lsp_buf_range_formatting()
  if not pcall(vim.lsp.buf.range_formatting) then
    cmd("'<,'>Neoformat")
  end
end

function vim_lsp_buf_formatting()
  if not pcall(vim.lsp.buf.formatting) then
    cmd('Neoformat')
  end
end

cmd('command! LspAttachBuffer :lua attach_lsp_to_new_buffer()<cr>')
u.augroup('x_nvim_lsp', {
    BufNewFile = {
      { "*", attach_lsp_to_new_buffer }
    }
})
