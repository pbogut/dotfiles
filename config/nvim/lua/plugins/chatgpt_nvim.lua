local M = {}

function M.config()
  require('chatgpt').setup({
    api_key_cmd = os.getenv('HOME').. '/.scripts/gpg-config get chatgpt_api_key',
    chat = {
      keymaps = {
        cycle_modes = '<M-m>',
      },
    },
    popup_window = {
      border = {
        highlight = 'Normal',
      },
    },
    popup_input = {
      border = {
        highlight = 'Normal',
      },
    },
    actions_paths = {
      os.getenv('HOME') .. '/.config/nvim/lua/plugins/chatgpt_nvim.actions.json',
    },
  })
end

return M
