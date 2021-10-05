local u = require('utils')
local g = vim.g

local function config()
  g.neoformat_only_msg_on_error = 1
  g.neoformat_vimwiki_prettier = {
    exe = 'prettier',
    args = {'--stdin', '--stdin-filepath', '%:p'},
    stdin = 1,
  }
  g.neoformat_disable_on_save = 1
  g.neoformat_enabled_vimwiki = {'prettier'}

  g.neoformat_basic_format_align = 1
end

local function setup()
  u.map('n', '<space>af', ':Neoformat<cr>')
end


return {
  config = config,
  setup = setup,
}
