--@type LazyPluginSpec
return {
  enabled = true,
  'luckasranarison/tailwind-tools.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- optional
    'nvim-treesitter/nvim-treesitter',
  },
  build = ':UpdateRemotePlugins',
  ft = {
    'blade',
    'html',
    'php',
    'eelixir',
    'elixir',
    'handlebars',
    'templ',
    'template',
  },
  opts = {}, -- your configuration
  config = function(opts)
    require('tailwind-tools').setup(opts)
    vim.g.tailwind_tools_loaded = true
    local augroup = vim.api.nvim_create_augroup('x_tailwind_tools', { clear = true })
    local command = vim.api.nvim_create_user_command

    command('TailwindSortOnSaveDisable', function(opt)
      if opt.bang then
        vim.g.tailwind_tools_sort_on_save = false
        vim.b.tailwind_tools_sort_on_save = false
      else
        vim.b.tailwind_tools_sort_on_save = false
      end
    end, { bang = true })

    command('TailwindSortOnSaveEnable', function(opt)
      if opt.bang then
        vim.g.tailwind_tools_sort_on_save = true
        vim.b.tailwind_tools_sort_on_save = true
      else
        vim.b.tailwind_tools_sort_on_save = true
      end
    end, { bang = true })

    command('TailwindSortOnSaveToggle', function(opt)
      if opt.bang then
        vim.g.tailwind_tools_sort_on_save = not vim.g.tailwind_tools_sort_on_save
        vim.b.tailwind_tools_sort_on_save = vim.g.tailwind_tools_sort_on_save
      else
        if vim.b.tailwind_tools_sort_on_save == nil then
          vim.b.tailwind_tools_sort_on_save = not vim.g.tailwind_tools_sort_on_save
        else
          vim.b.tailwind_tools_sort_on_save = not vim.b.tailwind_tools_sort_on_save
        end
      end
    end, { bang = true })

    vim.g.tailwind_tools_sort_on_save = true
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = augroup,
      pattern = '*',
      callback = function()
        if vim.b.tailwind_tools_sort_on_save == nil then
          if vim.g.tailwind_tools_sort_on_save == true then
            vim.cmd.TailwindSortSync()
          end
        else
          if vim.b.tailwind_tools_sort_on_save == true then
            vim.cmd.TailwindSortSync()
          end
        end
      end,
    })
  end,
}
