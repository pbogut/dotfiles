local null_ls = require('null-ls')
local on_attach = require('plugins.nvim_lsp').on_attach
local severity = vim.diagnostic.severity

local cfg = { sources = {}, on_attach = on_attach }

local sources = {
  -- lua
  {
    builtin = null_ls.builtins.diagnostics.luacheck,
    enabled = false,
  },
  {
    builtin = null_ls.builtins.diagnostics.selene,
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
  {
    builtin = null_ls.builtins.code_actions.shellcheck,
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
    enabled = false,
  },
  {
    builtin = null_ls.builtins.formatting.isort,
    enabled = true,
  },
  {
    builtin = null_ls.builtins.formatting.yapf,
    enabled = true,
  },
  -- json
  {
    builtin = null_ls.builtins.diagnostics.jsonlint,
    enabled = true,
  },
  -- sql
  {
    builtin = null_ls.builtins.diagnostics.sqlfluff,
    extra_args = { '--dialect', 'mysql' },
    enabled = false,
  },
  {
    builtin = null_ls.builtins.formatting.sqlfluff,
    extra_args = { '--dialect', 'mysql' },
    enabled = true,
  },
  -- other
  {
    builtin = null_ls.builtins.diagnostics.editorconfig_checker,
    lower_servity = 3,
    enabled = function()
      return vim.fn.filereadable(vim.fn.getcwd() .. '/.editorconfig') == 1
    end,
  },
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

local function min(a, b)
  if a < b then
    return a
  end
  return b
end

--[[ local yo = 3 ]]
local function lower_servity(builtin, level)
  level = level or 1

  local lower_entry_servity = function(entry)
    local current_servity = entry.severity or severity.ERROR
    entry.severity = min(current_servity + level, severity.HINT)
  end

  local on_output = builtin._opts.on_output
  builtin._opts.on_output = function(...)
    local result = on_output(...)
    if type(result) == 'table' and result.message then
      lower_entry_servity(result)
    elseif type(result) == 'table' and #result > 0 and result[1].message then
      for _, entry in ipairs(result) do
        lower_entry_servity(entry)
      end
    end
    return result
  end

  return builtin
end

for _, source in ipairs(sources) do
  if source.extra_args then
    source.builtin = source.builtin.with({
      extra_args = source.extra_args,
    })
  end
  if source.lower_servity then
    source.builtin = lower_servity(source.builtin, source.lower_servity)
  end
  if source.filetypes then
    source.builtin.filetypes = source.filetypes
  end
  if source.args then
    source.builtin._opts.args = source.args
  end
  if source.enabled == nil or source.enabled == true or type(source.enabled) == 'function' and source.enabled() then
    cfg.sources[#cfg.sources + 1] = source.builtin
  end
end

null_ls.setup(cfg)
