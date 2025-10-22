---@type LazyPluginSpec
return {
  enabled = false,
  'jackmort/chatgpt.nvim',
  dependencies = {
    'muniftanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  keys = {
    { '<space>gpt', '<cmd>ChatGPT<cr>' },
    { '<space>rg', '<plug>(chatgpt-action-list)', mode = { 'n', 'v' } },
  },
  cmd = { 'ChatGPT', 'ChatEditWithInstructions', 'ChatGPTRun' },
  init = function()
    local k = vim.keymap
    k.set({ 'n', 'v' }, '<plug>(chatgpt-action-list)', function()
      vim.h.send_esc() -- needs for visual, so selection is remembered
      vim.cmd('Lazy load telescope.nvim')
      local actions = {
        'email_casual',
        'email_professional',
        'grammar_correction',
        'generate_cli_command',
      }
      if #actions == 0 then
        vim.notify('No actions found.', vim.log.levels.INFO, { title = 'Actions' })
        return
      end
      table.sort(actions, function(a1, a2)
        return a1 < a2
      end)
      vim.ui.select(actions, { prompt = 'Select action: ' }, function(action)
        if action then
          vim.cmd.ChatGPTRun(action)
        end
        vim.cmd.stopinsert()
      end)
    end)
  end,
  config = function()
    require('chatgpt').setup({
      api_key_cmd = 'bash ' .. os.getenv('HOME') .. '/.scripts/secret chatgpt/api_key',
      openai_params = {
        model = 'gpt-4o-mini',
      },
      chat = {
        keymaps = {
          cycle_modes = '<M-m>',
        },
      },
      popup_window = {
        border = {
          highlight = 'FloatBorder',
        },
        win_options = {
          winhighlight = 'Normal:FloatNormal,FloatBorder:FloatBorder',
        },
      },
      popup_input = {
        border = {
          highlight = 'FloatBorder',
        },
        win_options = {
          winhighlight = 'Normal:FloatNormal,FloatBorder:FloatBorder',
        },
      },
      actions_paths = {
        os.getenv('HOME') .. '/.config/nvim/chatgpt_nvim.actions.json',
      },
    })
  end,
}
