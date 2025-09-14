local config = require('pbogut.config')
local fake_home = os.getenv('HOME') .. '/.config'
local opts = {
  on_init = function(client)
    local project_path = client.workspace_folders[1].name
    local composer_json = project_path .. '/composer.json'
    local composer = nil
    if vim.fn.filereadable(composer_json) == 1 then
      composer = vim.json.decode(vim.h.read_file(composer_json))
    end
    local composerPhpVer = vim.h.deep_get(composer, 'config.platform.php')
    if vim.h.deep_get(composer, 'config.platform.php') then
      print('Configuring intelephense for php ' .. composerPhpVer)
      local settings = client.config.settings
      vim.h.deep_set(settings, 'intelephense.environment.phpVersion', composerPhpVer)
      client.notify('workspace/didChangeConfiguration', { settings = settings })
    end
    return true
  end,
  cmd = {
    'sh',
    '-c',
    'HOME=' .. fake_home .. ' intelephense --stdio',
  },
  filetypes = { 'php', 'blade', 'html' },
  settings = {
    intelephense = {
      files = {
        associations = {
          '*.php',
          '*.phtml',
          '*.blade.php',
        },
      },
    },
  },
  get_language_id = function(bufnr, filetype)
    if filetype == 'blade' then
      filetype = 'php'
    end
    return filetype
  end,
}
config.apply_to(opts.settings, 'intelephense', 'lsp.intelephense')
return opts
