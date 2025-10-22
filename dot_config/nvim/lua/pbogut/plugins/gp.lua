---@type LazyPluginSpec
return {
  enabled = true,
  'robitx/gp.nvim',
  keys = {
    { '<space>gp', '<cmd>GpChatFinder<cr>' },
  },
  cmd = {
    'GpAgent',
    'GpAppend',
    'GpChatDelete',
    'GpChatFinder',
    'GpChatLast',
    'GpChatNew',
    'GpChatPaste',
    'GpChatRespond',
    'GpChatToggle',
    'GpContext',
    'GpEnew',
    'GpImage',
    'GpImageAgent',
    'GpImplement',
    'GpInspectLog',
    'GpInspectPlugin',
    'GpNew',
    'GpNextAgent',
    'GpPopup',
    'GpPrepend',
    'GpRewrite',
    'GpSelectAgent',
    'GpStop',
    'GpTabnew',
    'GpVnew',
    'GpWhisper',
    'GpWhisperAppend',
    'GpWhisperEnew',
    'GpWhisperNew',
    'GpWhisperPopup',
    'GpWhisperPrepend',
    'GpWhisperRewrite',
    'GpWhisperTabnew',
    'GpWhisperVnew',
  },
  config = function()
    local conf = {
      providers = {
        openai = {
          endpoint = 'https://api.openai.com/v1/chat/completions',
          secret = vim.h.read_exec('bash ' .. os.getenv('HOME') .. '/.scripts/secret chatgpt/api_key'),
        },
      },
    }
    require('gp').setup(conf)

    local command = vim.api.nvim_create_user_command

    command('GpChatFinder', function()
      require("telescope.builtin").live_grep({
        attach_mappings = function(bufnr, map)
          map('i', '<C-n>', function()
            require("telescope.actions").close(bufnr)
            vim.cmd.GpChatNew()
          end)
          return true
        end,
        prompt_title = "Search AI Chats (<C-n> to start new)",
        cwd = require("gp").config.chat_dir,
        default_text = "topic: ",
        vimgrep_arguments = {
          "rg",
          "--column",
          "--smart-case",
          "--sortr=modified",
        },
      })
    end, {})
  end,
}
