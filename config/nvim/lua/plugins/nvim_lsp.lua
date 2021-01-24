local lspconfig = require('lspconfig')
local buf_map = vim.api.nvim_buf_set_keymap
local map = vim.api.nvim_set_keymap
local opts = { noremap=true, silent=true }

-- prevent stupid errors when using mapping with no lsp attached
map('n', '<C-k>', '<cmd>lua print("No LSP attached")<CR>', opts)
map('i', '<C-k>', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>i', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>T', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>rn', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>rr', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>d', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>sd', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>sD', '<cmd>lua print("No LSP attached")<CR>', opts)
map('n', '<space>ca', '<cmd>lua print("No LSP attached")<CR>', opts)

local on_attach = function(_, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  require'completion'.on_attach()

  -- Mappings.
  buf_map(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_map(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_map(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_map(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_map(bufnr, 'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_map(bufnr, 'n', '<space>i', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_map(bufnr, 'n', '<space>T', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_map(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_map(bufnr, 'n', '<space>rr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_map(bufnr, 'n', '<space>d', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_map(bufnr, 'n', '<space>sd', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  buf_map(bufnr, 'n', '<space>sD', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  buf_map(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
end

local servers = {'intelephense', 'vimls', 'vuels', 'jsonls', 'bashls',
                 'pyls_ms', 'elixirls', 'gopls', 'tsserver'}
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
  }
end
lspconfig['sumneko_lua'].setup {
  on_attach = on_attach,
  settings = { Lua = { diagnostics = { globals = {'vim'} } } }
}

local client_list = {}

local function get_active_client_map()
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

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    -- Enable underline, use default values
    underline = true,
    -- Enable virtual text, override spacing to 8
    virtual_text = {
      spacing = 8,
      prefix = "■",
    },
    -- Disable a feature
    update_in_insert = false,
  }
)
