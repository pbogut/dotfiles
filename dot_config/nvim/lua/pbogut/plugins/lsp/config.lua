local b = {} -- binding related
local h = {} -- helper functions

local bindings = function()
  return {
    { 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', b.no_lsp_bind },
    { 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', b.no_lsp_bind },
    { 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', false },
    { 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', false },
    { 'n', '<c-k>', b.snippet_jump_back_or_signature_action, b.snippet_jump_back_or_signature_action },
    { 'i', '<c-k>', b.snippet_jump_back_or_signature_action, b.snippet_jump_back_or_signature_action },
    {
      { 'n', 'i' },
      '<m-i>',
      function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end,
      b.no_lsp_bind,
    },
    { 'n', 'gd', b.maybe_telescope('definition'), false },
    { 'n', '<space>ld', b.maybe_telescope('definition'), b.no_lsp_bind },
    { 'n', '<space>lD', '<cmd>lua vim.lsp.buf.declaration()<cr>', b.no_lsp_bind },
    { 'n', '<space>li', b.maybe_telescope('implementation'), b.no_lsp_bind },
    { 'n', '<space>lt', b.maybe_telescope('type_definition'), b.no_lsp_bind },
    { 'n', '<space>lr', b.maybe_telescope('references'), b.no_lsp_bind },
    { 'n', '<space>ls', b.maybe_telescope('document_symbol'), b.no_lsp_bind },
    { 'n', '<space>lS', b.maybe_telescope('workspace_symbol'), b.no_lsp_bind },
    { 'n', '<space>lc', vim.lsp.buf.code_action, b.no_lsp_bind },

    { 'n', '<space>rn', b.lsp_rename, b.no_lsp_bind, { silent = false } },
    { 'n', '<space>el', '<cmd>lua vim.diagnostic.open_float(0, {scope = "line"})<cr>', b.no_lsp_bind },
    { 'n', '<space>ee', '<cmd>Trouble diagnostics<cr>', b.no_lsp_bind },
    { 'n', '<space>eo', '<cmd>DiagnosticsBufferToggle<cr>', b.no_lsp_bind },
    { 'n', '<space>af', b.lsp_formatting, 'migg=G`i' },
    { 'v', '<space>af', b.lsp_formatting, b.no_lsp_bind },
    { 'x', '<space>af', b.lsp_formatting, b.no_lsp_bind },
  }
end

local cfg = {
  vanilla = {
    definition = 'lua vim.lsp.buf.definition()',
    implementation = 'lua vim.lsp.buf.implementation()',
    type_definition = 'lua vim.lsp.buf.type_definition()',
    references = 'lua vim.lsp.buf.references()',
    document_symbol = 'lua vim.lsp.buf.document_symbol()',
    workspace_symbol = 'lua vim.lsp.buf.workspace_symbol()',
    diagnostics = 'lua vim.diagnostic.open_float({scope = "buffer"})',
  },
  telescope = {
    definition = 'lua require("telescope.builtin").lsp_definitions({show_line = false})',
    implementation = 'Telescope lsp_implementations',
    type_definition = 'Telescope lsp_type_definitions',
    references = 'Telescope lsp_references',
    document_symbol = 'Telescope lsp_document_symbols',
    workspace_symbol = 'Telescope lsp_workspace_symbols',
    diagnostics = [[lua require('telescope.builtin').diagnostics({bufnr = 0})]],
  },
  navic_disable = {
    efm = true,
    tailwindcss = true,
    gopls = true,
    templ = true,
  },
  navic_ext = {
    phtml = { 'intelephense' },
    php = { 'intelephense' },
  },
  servers = {
    -- { name = 'clangd', snippet_support = true },
    -- { name = 'denols' },
    -- { name = 'phpactor', snippet_support = true },
    -- { name = 'pylsp' },
    -- { name = 'pyright' },
    { name = 'sqlls' },
    { name = 'bashls' },
    { name = 'ccls' },
    { name = 'cssls', snippet_support = true },
    { name = 'dockerls' },
    { name = 'efm' },
    { name = 'expert', snippet_support = true },
    { name = 'gdscript' },
    { name = 'gopls' },
    { name = 'html', snippet_support = true, rename = false, format = { templ = false } },
    -- { name = 'htmx', snippet_support = true },
    { name = 'intelephense', snippet_support = true },
    { name = 'jedi_language_server' },
    { name = 'jsonls', snippet_support = true },
    { name = 'lemminx' },
    { name = 'lua_ls', snippet_support = true, format = false },
    { name = 'ocamllsp' },
    { name = 'openscad_lsp' },
    -- { name = 'rust_analyzer' }, -- loaded from rust_tools
    { name = 'solargraph' },
    { name = 'tailwindcss', snippet_support = true },
    { name = 'templ' },
    { name = 'ts_ls' },
    { name = 'vimls' },
    -- { name = 'vuels' },
    { name = 'zls' },
  },
}

on_attach = function(client, bufnr)
  client.server_capabilities.documentHighlightProvider = false
  client.server_capabilities.foldingRangeProvider = false
  -- vim.notify(client.name)
  -- vim.print(client.server_capabilities)

  local has_navic, navic = pcall(require, 'nvim-navic')
  if has_navic then
    if not cfg.navic_disable[client.name] then
      local ext = h.get_ext(bufnr)
      if cfg.navic_ext[ext] then
        for _, allowed_client in pairs(cfg.navic_ext[ext]) do
          if client.name == allowed_client then
            navic.attach(client, bufnr)
          end
        end
      else
        navic.attach(client, bufnr)
      end
    end
  end

  if has_lsp_signature then
    lsp_signature.on_attach({
      bind = true,
      doc_lines = 10,
      floating_window = true,
      floating_window_above_cur_line = true,
      hint_enable = false,
      handler_opts = { border = 'none' },
      toggle_key = '<plug>(lsp_signature_toggle_key)',
    })
  end

  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  if has_lspstatus then
    lspstatus.on_attach(client, bufnr)
  end

  -- Mappings.
  for _, def in pairs(bindings()) do
    local opts = def[5] or {}
    opts.buffer = bufnr
    vim.keymap.set(def[1], def[2], def[3], opts)
  end
end

b.no_lsp_bind = '<cmd>lua print("No LSP attached")<cr>'
b.lsp_rename = function()
  vim.lsp.buf.rename(nil, {
    filter = function(client)
      return h.server_cfg(client.name, 'rename', true)
    end,
  })
end
b.signature_action = crequire('lsp_signature', {
  done = function()
    return '<cmd>lua require"lsp_signature".toggle_float_win()<cr>'
  end,
  fail = function()
    return '<cmd>lua vim.lsp.buf.signature_help()<cr>'
  end,
})
b.snippet_jump_back_or_signature_action = function()
  local has_lspsign, lspsign = pcall(require, 'lsp_signature')
  local has_luasnip, luasnip = pcall(require, 'luasnip')
  local done = false
  if not done and has_luasnip then
    if luasnip.jumpable(-1) then
      luasnip.jump(-1)
      done = true
    end
  end
  if not done and has_lspsign then
    lspsign.toggle_float_win()
    done = true
  end
  if not done then
    vim.lsp.buf.signature_help()
    done = true
  end
end
b.maybe_telescope = function(name)
  return function()
    if vim.fn.exists(':Telescope') then
      vim.cmd(cfg.telescope[name])
    else
      vim.cmd(cfg.vanilla[name])
    end
  end
end
b.lsp_formatting = function(bufnr)
  vim.lsp.buf.format({
    filter = function(client)
      local cfg = h.server_cfg(client.name, 'format', true)
      if type(cfg) == 'table' then
        if cfg[vim.o.ft] == nil then
          return true
        end
        return cfg[vim.o.ft]
      end
      return cfg
    end,
    bufnr = bufnr,
  })
end

h.get_ext = function(bufnr)
  local bufinfo = vim.fn.getbufinfo(bufnr)
  if #bufinfo > 0 then
    local fname = bufinfo[1].name
    return vim.fn.fnamemodify(fname, ':e')
  end
end
h.server_cfg = function(server_name, key, default)
  for _, server in ipairs(cfg.servers) do
    if server.name == server_name then
      if server[key] ~= nil then
        return server[key]
      end
      break
    end
  end

  return default
end

-- prevent stupid errors when using mapping with no lsp attached
for _, def in pairs(bindings()) do
  if def[4] then
    vim.keymap.set(def[1], def[2], def[4])
  end
end

return {
  on_attach = on_attach,
  lsp_formatting = b.lsp_formatting,
  servers = cfg.servers,
}
