local u = require'utils'
local lspconfig = require('lspconfig')
local cmd = vim.cmd

-- prevent stupid errors when using mapping with no lsp attached
u.map('n', '<C-k>', '<cmd>lua print("No LSP attached")<CR>')
u.map('i', '<C-k>', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>i', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>T', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>rn', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>rr', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>d', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>sd', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>sD', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>ca', '<cmd>lua print("No LSP attached")<CR>')
u.map('n', '<space>af', '<cmd>lua print("No LSP attached")<CR>')
u.map('v', '<space>af', '<cmd>lua print("No LSP attached")<CR>')
u.map('x', '<space>af', '<cmd>lua print("No LSP attached")<CR>')

local on_attach = function(_, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  require'completion'.on_attach()

  -- Mappings.
  u.buf_map(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  u.buf_map(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  u.buf_map(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  u.buf_map(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  u.buf_map(bufnr, 'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  u.buf_map(bufnr, 'n', '<space>i', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  u.buf_map(bufnr, 'n', '<space>T', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  u.buf_map(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
  u.buf_map(bufnr, 'n', '<space>rr', '<cmd>lua vim.lsp.buf.references()<CR>')
  u.buf_map(bufnr, 'n', '<space>d', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>')
  u.buf_map(bufnr, 'n', '<space>sd', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
  u.buf_map(bufnr, 'n', '<space>sD', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>')
  u.buf_map(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  -- @todo fall back to migg=G`i and = if not available (how to detect?)
  u.buf_map(bufnr, 'n', '<space>af', '<cmd>lua vim.lsp.buf.formatting()<CR>')
  u.buf_map(bufnr, 'v', '<space>af', '<cmd>lua vim.lsp.buf.range_formatting()<CR>')
  u.buf_map(bufnr, 'x', '<space>af', '<cmd>lua vim.lsp.buf.range_formatting()<CR>')
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

-- npm install -g intelephense
lspconfig.intelephense.setup { on_attach = on_attach }
-- npm install -g vim-language-server
lspconfig.vimls.setup { on_attach = on_attach }
-- npm install -g vls
lspconfig.vuels.setup { on_attach = on_attach }
-- npm install -g bash-language-server
lspconfig.bashls.setup { on_attach = on_attach }
-- npm install -g vscode-css-languageserver-bin
lspconfig.cssls.setup { on_attach = on_attach }
-- GO111MODULE=on go get golang.org/x/tools/gopls@latest
lspconfig.gopls.setup { on_attach = on_attach }
-- npm install -g typescript-language-server
lspconfig.tsserver.setup { on_attach = on_attach }
-- npm install -g pyright
lspconfig.pyright.setup { on_attach = on_attach }
-- npm install -g vscode-json-languageserver
require 'plugins.lsp.jsonls'.setup(on_attach)
-- see https://github.com/sumneko/lua-language-server/wiki/Build-and-Run-(Standalone)
require 'plugins.lsp.sumneko_lua'.setup(on_attach)
-- see ./lsp/pyls_ms.lua
require 'plugins.lsp.pyls_ms'.setup(on_attach)

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

cmd('command! LspAttachBuffer :lua attach_lsp_to_new_buffer()<cr>')
u.augroup('x_nvim_lsp', {
    BufNewFile = {
      { "*", attach_lsp_to_new_buffer }
    }
})
