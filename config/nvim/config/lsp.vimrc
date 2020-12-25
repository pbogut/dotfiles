:lua << EOF
  local lspconfig = require('lspconfig')

  local on_attach = function(_, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    require'diagnostic'.on_attach()
    require'completion'.on_attach()

    -- Mappings.
    local opts = { noremap=true, silent=true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>i', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>T', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>rr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>d', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>sd', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>sD', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  end


  -- local servers = {'rust_analyzer', 'sumneko_lua'}
  -- local servers = {}
  local servers = {'intelephense', 'vimls', 'vuels', 'jsonls', 'bashls', 'pyls_ms', 'elixirls', 'gopls', 'sumneko_lua', 'tsserver'}
  for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
      on_attach = on_attach,
    }
  end

  -- lspconfig['intelephense'].setup { on_attach = on_attach }
  -- lspconfig['vimls'].setup { on_attach = on_attach }
  -- lspconfig['vuels'].setup { on_attach = on_attach }
  -- lspconfig['jsonls'].setup { on_attach = on_attach }
  -- lspconfig['bashls'].setup { on_attach = on_attach }
  -- lspconfig['pyls_ms'].setup { on_attach = on_attach }
  -- lspconfig['elixirls'].setup { on_attach = on_attach }
  -- lspconfig['gopls'].setup { on_attach = on_attach, cmd = { "typescript-language-server", "--stdio" } }
  -- lspconfig['tsserver'].setup { on_attach = on_attach, cmd = { "typescript-language-server", "--stdio" } }

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
EOF

autocmd BufNewFile * :lua attach_lsp_to_new_buffer()
command! LspAttachBuffer :lua attach_lsp_to_new_buffer()<cr>

" prevent stupid errors when using mapping with no lsp attached
nnoremap <C-k> <cmd>lua print("No LSP attached")<CR>
inoremap <C-k> <cmd>lua print("No LSP attached")<CR>
nnoremap <space>i <cmd>lua print("No LSP attached")<CR>
nnoremap <space>T <cmd>lua print("No LSP attached")<CR>
nnoremap <space>rn <cmd>lua print("No LSP attached")<CR>
nnoremap <space>rr <cmd>lua print("No LSP attached")<CR>
nnoremap <space>d <cmd>lua print("No LSP attached")<CR>
nnoremap <space>sd <cmd>lua print("No LSP attached")<CR>
nnoremap <space>sD <cmd>lua print("No LSP attached")<CR>
