:lua << EOF
  local nvim_lsp = require('nvim_lsp')

  local on_attach = function(_, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    require'diagnostic'.on_attach()
    require'completion'.on_attach()

    -- Mappings.
    local opts = { noremap=true, silent=true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>T', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>rr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>d', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>', opts)
  end

  -- local servers = {'rust_analyzer', 'sumneko_lua'}
  local servers = {'intelephense', 'vimls', 'vuels', 'jsonls', 'bashls', 'pyls_ms', 'elixirls', 'gopls'}
  for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
      on_attach = on_attach,
    }
  end

  -- nvim_lsp['intelephense'].setup { on_attach = on_attach }
  -- nvim_lsp['vimls'].setup { on_attach = on_attach }
  -- nvim_lsp['vuels'].setup { on_attach = on_attach }
  -- nvim_lsp['jsonls'].setup { on_attach = on_attach }
  -- nvim_lsp['bashls'].setup { on_attach = on_attach }
  -- nvim_lsp['pyls_ms'].setup { on_attach = on_attach }
  -- nvim_lsp['elixirls'].setup { on_attach = on_attach }
  -- nvim_lsp['gopls'].setup { on_attach = on_attach, cmd = { "typescript-language-server", "--stdio" } }
  -- nvim_lsp['tsserver'].setup { on_attach = on_attach, cmd = { "typescript-language-server", "--stdio" } }
EOF
