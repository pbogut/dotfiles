---@type LazyPluginSpec
return {
  'rest-nvim/rest.nvim',
  keys = {
    {
      '<space>H',
      function()
        if not vim.b._rest_nvim_env_file then
          vim.cmd('Rest env select')
        else
          vim.b._x_context = 'env: ' .. vim.fs.basename(vim.b._rest_nvim_env_file)
          vim.g._rest_last_env = vim.b._rest_nvim_env_file
          vim.cmd('Rest run')
          vim.cmd.wincmd('H')
          vim.cmd.wincmd('l')
        end
      end,
      desc = 'Rest run',
    },
  },
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('rest-nvim').setup({})

    _G.rest_nvim = {
      set_env = function(env_file, key, value)
        if not env_file then
            return
        end
        local file = io.open(env_file, 'r')
        if not file then
            return
        end
        local file_content = {}
        for line in file:lines() do
            if line:sub(1, key:len() + 1) == (key .. '=') then
              table.insert(file_content, key .. '=' .. value)
            else
              table.insert(file_content, line)
            end
        end
        io.close(file)

        file = io.open(env_file, 'w')
        if not file then
            return
        end
        for _, val in ipairs(file_content) do
            file:write(val..'\n')
        end
        io.close(file)
      end
    }

    local group = vim.api.nvim_create_augroup('x_vim_http', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = group,
      pattern = 'rest_nvim_result',
      callback = function()
        vim.keymap.set('n', 'q', '<cmd>bd<cr>', { buffer = true })
        vim.keymap.set('n', '<space>H', function()
          vim.cmd.wincmd('h')
          vim.cmd('Rest run')
          vim.cmd.wincmd('l')
        end, { buffer = true })
      end,
    })
  end,
}
