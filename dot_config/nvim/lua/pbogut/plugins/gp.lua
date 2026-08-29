---@type LazyPluginSpec
return {
  enabled = false,
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
    local gp = require('gp')
    local system_prompt = 'You are a general AI assistant.\n\n'
      .. 'The user provided the additional info about how they would like you to respond:\n\n'
      .. "- If you're unsure don't guess and say you don't know instead.\n"
      .. '- Ask question if you need clarification to provide better answer.\n'
      .. "- Don't elide any code from your output if the answer requires coding.\n"
      .. '- Go straight to the point.\n'
      .. '- If question can be answered with one sentence, answer it. Dont over complicate this.\n'
      .. '- Dont act smart, I know what you are, you know what you are, if you got the answer give it, if not then just say it, dont try to be smarter than you are.\n'
      .. "- Take a deep breath; You've got this!\n"
    local conf = {
      providers = {
        openai = {
          endpoint = 'https://api.openai.com/v1/chat/completions',
          secret = vim.h.read_exec('bash ' .. os.getenv('HOME') .. '/.scripts/secret chatgpt/api_key'),
        },
        openai_ap = {
          endpoint = 'https://api.openai.com/v1/chat/completions',
          secret = vim.h.read_exec('bash ' .. os.getenv('HOME') .. '/.scripts/secret openai_ap/api_key'),
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
          provider = 'openai_ap',
          name = 'gpt-5.5 high (ap)',
          chat = true,
          command = false,
          -- string with model name or table with model name and parameters
          model = {
            reasoning_effort = 'high',
            model = 'gpt-5.5',
            -- temperature = 1.1,
            -- top_p = 1,
          },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = require('gp.defaults').chat_system_prompt,
        },
        {
          provider = 'openai_ap',
          name = 'gpt-5.5 low (ap)',
          chat = true,
          command = false,
          -- string with model name or table with model name and parameters
          model = {
            reasoning_effort = 'low',
            model = 'gpt-5.5',
            -- temperature = 1.1,
            -- top_p = 1,
          },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = require('gp.defaults').chat_system_prompt,
        },
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
    gp.setup(conf)
    local prepare_payload = gp.dispatcher.prepare_payload
    gp.dispatcher.prepare_payload = function(messages, model, provider)
      output = prepare_payload(messages, model, provider)
      if model.reasoning_effort then
        output.reasoning_effort = model.reasoning_effort
      end
      return output
    end

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
