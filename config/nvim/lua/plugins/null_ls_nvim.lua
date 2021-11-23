local null_ls = require('null-ls')
local h = require('null-ls.helpers')
local on_attach = require('plugins.nvim_lsp').on_attach
local s = h.diagnostics.severities
local os = {}

local cfg = { sources = {} }

local sources = {
  { builtin = null_ls.builtins.formatting.stylua },
  {
    builtin = null_ls.builtins.formatting.prettier,
    filetypes = { 'markdown' },
  },
  {
    builtin = null_ls.builtins.diagnostics.phpcs,
    lower_servity = 2,
    enabled = function()
      return vim.fn.filereadable(vim.fn.getcwd() .. '/phpcs.xml') == 1
    end,
  },
  { builtin = null_ls.builtins.diagnostics.luacheck, enabled = false },
  { builtin = null_ls.builtins.completion.spell, enabled = false },
  { builtin = null_ls.builtins.formatting.phpcbf, enabled = false },
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
  if
    source.enabled == nil
    or source.enabled == true
    or type(source.enabled) == 'function' and source.enabled()
  then
    cfg.sources[#cfg.sources + 1] = source.builtin
  end
end

require('null-ls').config(cfg)
require('lspconfig')['null-ls'].setup({ on_attach = on_attach })
