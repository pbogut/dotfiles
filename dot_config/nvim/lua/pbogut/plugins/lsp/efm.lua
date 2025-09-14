local function exec(bin, ...)
  local args = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(args, vim.fn.shellescape(v))
  end

  local sep = #args > 0 and ' ' or ''

  bin = mason_bin(bin) or bin
  return bin .. sep .. table.concat(args, ' ')
end

local cfg = {
  format = {
    gdformat = {
      formatCommand = exec('gdformat', '-'),
      formatStdin = true,
      rootMarkers = { 'project.godot' },
    },
    stylua = {
      formatCommand = exec('stylua', '--color=Never', '-'),
      formatStdin = true,
      rootMarkers = { 'stylua.toml', '.stylua.toml' },
    },
    phpcbf = {
      formatCommand = exec('phpcbf', '-'),
      formatStdin = true,
      rootMarkers = { '.phpcs.xml', 'phpcs.xml', '.phpcs.xml.dist', 'phpcs.xml.dist', 'composer.json' },
    },
    shfmt = {
      formatCommand = exec('shfmt', '-ci', '-sr', '-i', '4', '-'),
      formatStdin = true,
      rootMarkers = {},
    },
    prettier = {
      formatCommand = exec('prettier', '--stdin', '--stdin-filepath', '${INPUT}'),
      formatStdin = true,
    },
    yapf = {
      formatCommand = exec('yapf'),
      formatStdin = true,
      rootMarkers = { '.style.yapf', 'setup.cfg', 'pyproject.toml' },
    },
    elixir_formatter = {
      formatCommand = exec('mix', 'format', '-'),
      formatStdin = true,
      rootMarkers = { '.formatter.exs' },
    },
  },
  lint = {
    golangci_lint = {
      prefix = 'golangci-lint',
      lintSource = 'efm/golangci-lint',
      lintCommand = exec('golangci-lint', 'run', '--color=never', '--out-format=tab', '${INPUT}'),
      lintStdin = false,
      lintFormats = { '%.%#:%l:%c %m' },
      rootMarkers = {},
    },
    editorconfig_checker = {
      prefix = 'editorconfig',
      lintSource = 'efm/editorconfig',
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
      lintSource = 'efm/phpcs',
      lintCommand = exec('phpcs', '--no-colors', '--report=emacs'),
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
      lintSource = 'efm/shellcheck',
      lintCommand = exec('shellcheck', '--color=never', '--format=gcc', '-'),
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
      lintSource = 'efm/jsonlint',
      lintCommand = exec('jsonlint', '--compact'),
      lintStdin = true,
      lintFormats = { 'line %l, col %c, %m' },
      rootMarkers = {},
    },
    vale = {
      prefix = 'vale',
      lintSource = 'efm/vale',
      lintCommand = exec('vale', '--output=line', '--config', os.getenv('HOME') .. '/vale/vale.ini'),
      lintStdin = true,
      lintFormats = { '%f:%l:%c:%m' },
      rootMarkers = {},
    },
  },
}

local opts = {
  init_options = { documentFormatting = true, codeAction = true },
  filetypes = {
    'css',
    'elixir',
    'gdscript',
    'handlebars',
    'heex',
    'javascript',
    'json',
    'less',
    'lua',
    'markdown',
    'php',
    'python',
    'sass',
    'scss',
    'sh',
    'typescript',
  },
  settings = {
    rootMarkers = { '.git/' },
    languages = {
      -- go = { cfg.lint.golangci_lint },
      css = { cfg.format.prettier },
      elixir = { cfg.format.elixir_formatter },
      gdscript = { cfg.format.gdformat },
      handlebars = { cfg.format.prettier },
      heex = { cfg.format.elixir_formatter },
      javascript = { cfg.format.prettier },
      json = { cfg.lint.jsonlint },
      less = { cfg.format.prettier },
      lua = { cfg.format.stylua },
      markdown = { cfg.format.prettier, cfg.lint.vale },
      php = { cfg.lint.phpcs, cfg.format.phpcbf },
      python = { cfg.format.yapf },
      sass = { cfg.format.prettier },
      scss = { cfg.format.prettier },
      sh = { cfg.lint.shellcheck, cfg.format.shfmt },
      typescript = { cfg.format.prettier },
      ['='] = { cfg.lint.editorconfig_checker },
    },
  },
}

return opts
