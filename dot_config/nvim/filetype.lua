-- vim.g.do_filetype_lua = 1
-- vim.g.did_load_filetypes = 0
vim.filetype.add({
  extension = {
    conf = 'conf',
    env = 'dotenv',
    keymap = 'devicetree',
    overlay = 'devicetree',
    http = 'http',
    templ = 'templ',
  },
  filename = {
    ['.env'] = 'dotenv',
    ['env'] = 'dotenv',
    ['tsconfig.json'] = 'jsonc',
    ['.yamlfmt'] = 'yaml',
  },
  pattern = {
    ['%.?env%.[%w_%..-]+'] = 'dotenv',
    ['.*/waybar/config'] = 'jsonc',
    ['/tmp/.*%.dump'] = 'zellijdump',
    ['.*%/environment.d%/.*%.conf'] = 'sh',
    ['.*%/waybar%/config'] = 'jsonc',
    -- chezmoi
    ['hyprland%.conf%.tmpl'] = 'hyprlang',
    ['.*%/environment.d%/.*%.conf%.tmpl'] = 'sh',
    ['.*%.toml%.tmpl'] = 'toml',
    ['.*%.json%.tmpl'] = 'json',
    ['.*%/dot_profile%.tmpl'] = 'sh',
    ['.*%/waybar%/config%.tmpl'] = 'jsonc',
    ['.*%.sh%.tmpl'] = 'sh',
    ['.*%.conf%.tmpl'] = 'conf',
    ['.*%.desktop%.tmpl'] = 'desktop',
  },
})
