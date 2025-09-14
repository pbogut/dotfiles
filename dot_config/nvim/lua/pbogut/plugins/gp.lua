---@type LazyPluginSpec
return {
  enabled = true,
  'robitx/gp.nvim',
  keys = {},
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
    -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
  end,
}
