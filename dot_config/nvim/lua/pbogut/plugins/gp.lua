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
        zen_comp = {
          endpoint = 'https://opencode.ai/zen/v1/chat/completions',
          secret = vim.h.read_exec('bash ' .. os.getenv('HOME') .. '/.scripts/secret opencodezen/api_key'),
        },
        zen_resp = {
          endpoint = 'https://opencode.ai/zen/v1/responses',
          secret = vim.h.read_exec('bash ' .. os.getenv('HOME') .. '/.scripts/secret opencodezen/api_key'),
        },
      },
      agents = {
        {
          provider = 'openai',
          name = 'gpt-5.2 (openai)',
          chat = true,
          command = false,
          -- string with model name or table with model name and parameters
          model = { model = 'gpt-5.2', temperature = 1.1, top_p = 1 },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = require('gp.defaults').chat_system_prompt,
        },
        {
          provider = 'openai',
          name = 'gpt-5.4 (openai)',
          chat = true,
          command = false,
          -- string with model name or table with model name and parameters
          model = { model = 'gpt-5.4', temperature = 1.1, top_p = 1 },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = require('gp.defaults').chat_system_prompt,
        },
        {
          provider = 'zen_comp',
          name = 'minimax-m2.5-free (zen)',
          chat = true,
          command = false,
          -- string with model name or table with model name and parameters
          model = { model = 'minimax-m2.5-free' },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = require('gp.defaults').chat_system_prompt,
        },
        {
          provider = 'zen_comp',
          name = 'minimax-m2.5 (zen)',
          chat = true,
          command = false,
          -- string with model name or table with model name and parameters
          model = { model = 'minimax-m2.5' },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = require('gp.defaults').chat_system_prompt,
        },
      },
    }
    require('gp').setup(conf)

    local command = vim.api.nvim_create_user_command

    command('GpChatFinder', function()
      require('telescope.builtin').live_grep({
        attach_mappings = function(bufnr, map)
          map('i', '<C-n>', function()
            require('telescope.actions').close(bufnr)
            vim.cmd.GpChatNew()
          end)
          return true
        end,
        prompt_title = 'Search AI Chats (<C-n> to start new)',
        cwd = require('gp').config.chat_dir,
        default_text = 'topic: ',
        vimgrep_arguments = {
          'rg',
          '--column',
          '--smart-case',
          '--sortr=modified',
        },
      })
    end, {})
  end,
}
