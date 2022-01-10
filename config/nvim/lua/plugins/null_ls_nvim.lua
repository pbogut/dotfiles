local null_ls = require('null-ls')
local h = require('null-ls.helpers')
local on_attach = require('plugins.nvim_lsp').on_attach
local s = h.diagnostics.severities
local os = {}

local cfg = { sources = {}, on_attach = on_attach }

local sources = {
  -- lua
  {
    builtin = null_ls.builtins.diagnostics.luacheck,
    enabled = false,
  },
  {
    builtin = null_ls.builtins.formatting.stylua,
    enabled = true,
  },
  -- bash
  {
    builtin = null_ls.builtins.formatting.shfmt,
    args = { '-i', '2', '-filename', '$FILENAME' },
    enabled = true,
  },
  -- php
  {
    builtin = null_ls.builtins.diagnostics.phpcs,
    lower_servity = 2,
    enabled = function()
      return vim.fn.filereadable(vim.fn.getcwd() .. '/phpcs.xml') == 1
    end,
  },
  {
    builtin = null_ls.builtins.formatting.phpcbf,
    enabled = false,
  },
  -- python
  {
    builtin = null_ls.builtins.diagnostics.flake8,
    enabled = true,
  },
  {
    builtin = null_ls.builtins.formatting.isort,
    enabled = true,
  },
  {
    builtin = null_ls.builtins.formatting.yapf,
    enabled = true,
  },
  -- other
  {
    builtin = null_ls.builtins.completion.spell,
    enabled = false,
  },
  {
    builtin = null_ls.builtins.formatting.prettier,
    filetypes = { 'markdown', 'css' },
    enabled = true,
  },
}

-- store original servity
os.error = s.error
os.warning = s.warning
os.information = s.information
os.hint = s.hint

local function min(a, b)
  if a < b then
    return a
  end
  return b
end

local function restore_servity()
  s.error = os.error
  s.warning = os.warning
  s.information = os.information
  s.hint = os.hint
end

local function lower_servity(builtin, level)
  level = level or 1
  local on_output = builtin._opts.on_output

  builtin._opts.on_output = function(...)
    -- lower level of servity
    s.error = min(os.error + level, os.hint)
    s.warning = min(os.warning + level, os.hint)
    s.information = min(os.information + level, os.hint)
    s.hint = min(os.hint + level, os.hint)
    local result = on_output(...)
    restore_servity()
    return result
  end

  return builtin
end

for _, source in ipairs(sources) do
  if source.lower_servity then
    source.builtin = lower_servity(source.builtin, source.lower_servity)
  end
  if source.filetypes then
    source.builtin.filetypes = source.filetypes
  end
  if source.args then
    source.builtin._opts.args = source.args
  end
  if
    source.enabled == nil
    or source.enabled == true
    or type(source.enabled) == 'function' and source.enabled()
  then
    cfg.sources[#cfg.sources + 1] = source.builtin
  end
end

null_ls.setup(cfg)
