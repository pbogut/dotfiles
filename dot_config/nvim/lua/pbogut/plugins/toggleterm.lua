---@type LazyPluginSpec
return {
  'akinsho/toggleterm.nvim',
  keys = {
    { '<space>lg', '<cmd>LazyGitToggle<cr>', desc = 'LazyGitToggle' },
    { '<space>eb', '<cmd>BaconToggle<cr>', desc = 'BaconToggle' },
  },
  cmd = { 'BaconToggle', 'LazyGitToggle' },
  config = function()
    require('toggleterm').setup()

    local command = vim.api.nvim_create_user_command
    local Terminal = require('toggleterm.terminal').Terminal

    local lg_cmd = 'lazygit'
      .. ' -ucf '
      .. (os.getenv('HOME') .. '/.config/lazygit/config.yml')
      .. ','
      .. (os.getenv('HOME') .. '/.config/lazygit/config-nvim.yml')

    local lazygit = Terminal:new({
      cmd = lg_cmd,
      direction = 'float',
      float_opts = {
        width = function(_)
          return vim.o.columns
        end,
        height = function(_)
          local statusheight = 1
          return vim.o.lines - vim.o.cmdheight - statusheight
        end,
        border = 'none',
      },
    })

    local bacon = Terminal:new({
      cmd = 'bacon',
      direction = 'float',
      on_open = function(term)
        vim.keymap.set({ 't', 'n', 'i' }, 'q', '<cmd>BaconToggle<cr>', { buffer = term.bufnr })
      end,
      float_opts = {
        width = function(_)
          return vim.o.columns
        end,
        height = function(_)
          local statusheight = 1
          return vim.o.lines - vim.o.cmdheight - statusheight
        end,
        border = 'none',
      },
    })

    command('LazyGitToggle', function()
      lazygit:toggle()
    end, {})

    command('BaconToggle', function()
      bacon:toggle()
    end, {})
  end,
}
