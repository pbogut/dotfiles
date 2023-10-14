local lspconfig = require('lspconfig')
local me = {}

local function exec(bin, args)
  if args then
    args = ' ' .. args
  else
    args = ''
  end
  bin = mason_bin(bin) or bin
  return bin .. args
end

function me.setup(opts)
  local cfg = {
    format = {
      stylua = {
        formatCommand = exec('stylua', '--color Never -'),
        formatStdin = true,
        rootMarkers = { 'stylua.toml', '.stylua.toml' },
      },
      phpcbf = {
        formatCommand = exec('phpcbf', '-'),
        formatStdin = true,
        rootMarkers = { '.phpcs.xml', 'phpcs.xml', '.phpcs.xml.dist', 'phpcs.xml.dist', 'composer.json' },
      },
      shfmt = {
        formatCommand = exec('shfmt', '-ci -sr -i 4 -'),
        formatStdin = true,
        rootMarkers = {},
      },
      prettier = {
        formatCommand = exec('prettier', '--stdin --stdin-filepath ${INPUT}'),
        formatStdin = true,
      },
      yapf = {
        formatCommand = exec('yapf'),
        formatStdin = true,
        rootMarkers = { '.style.yapf', 'setup.cfg', 'pyproject.toml' },
      },
    },
    lint = {
      editorconfig_checker = {
        prefix = 'editorconfig',
        lintCommand = exec('editorconfig-checker', '-no-color'),
        lintStdin = false,
        lintFormats = {
          '%t%l: %m', -- %t is tab character ackshually
        },
        lintCategoryMap = {
          ['	'] = 'N', -- all errors (tabs) as hints (notes)
        },
        rootMarkers = {
          '.editorconfig',
        },
      },
      phpcs = {
        prefix = 'phpcs',
        lintCommand = exec('phpcs', '--no-colors --report=emacs'),
        lintStdin = false,
        lintFormats = {
          '%.%#:%l:%c: %trror - %m',
          '%.%#:%l:%c: %tarning - %m',
        },
        lintCategoryMap = {
          e = 'I',
          w = 'N',
        },
        rootMarkers = {
          '.phpcs.xml',
          'phpcs.xml',
          '.phpcs.xml.dist',
          'phpcs.xml.dist',
          'composer.json',
        },
      },
      shellcheck = {
        prefix = 'shellcheck',
        lintCommand = exec('shellcheck', '--color=never --format=gcc -'),
        lintStdin = true,
        lintFormats = {
          '-:%l:%c: %trror: %m',
          '-:%l:%c: %tarning: %m',
          '-:%l:%c: %tote: %m',
        },
        rootMarkers = {},
      },

      jsonlint = {
        prefix = 'jsonlint',
        lintCommand = exec('jsonlint', '--compact'),
        lintStdin = true,
        lintFormats = { 'line %l, col %c, %m' },
        rootMarkers = {},
      },
    },
  }

  opts = vim.tbl_deep_extend('keep', opts, {
    init_options = { documentFormatting = true, codeAction = true },
    settings = {
      rootMarkers = { '.git/' },
      languages = {
        lua = { cfg.format.stylua },
        sh = { cfg.lint.shellcheck, cfg.format.shfmt },
        php = { cfg.lint.phpcs, cfg.format.phpcbf },
        python = { cfg.format.yapf },
        json = { cfg.lint.jsonlint },
        css = { cfg.format.prettier },
        less = { cfg.format.prettier },
        sass = { cfg.format.prettier },
        scss = { cfg.format.prettier },
        javascript = { cfg.format.prettier },
        typescript = { cfg.format.prettier },
        markdown = { cfg.format.prettier },
        ['='] = { cfg.lint.editorconfig_checker },
      },
    },
  })
  lspconfig.efm.setup(opts)
end

return me
