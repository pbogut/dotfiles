---@type LazyPluginSpec
return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = {
    { '<space>fr', '<plug>(telescope-live-grep)' },
    { '<space>st', '<plug>(telescope-file-types)' },
    { '<space>fa', '<plug>(telescope-find-files)' },
    { '<space>ff', '<plug>(telescope-find-files-no-ignore)' },
    { '<space>fF', '<plug>(telescope-find-files-with-hidden)' },
    { '<space>fb', '<plug>(telescope-buffers)' },
    { '<space>fO', '<plug>(telescope-old-files)' },
    { '<space>fo', '<plug>(telescope-old-files-in-cwd)' },
    { '<space>fg', '<plug>(telescope-git-files)' },
    { '<space>gw', '<plug>(telescope-grep-string)' },
    { '<space>ft', '<plug>(ts-templates-list)' },
    { '<space>fs', '<plug>(ts-snippets-list)' },
    -- { '<space>fc', '<plug>(ts-config-files)' },
    -- { '<space>fn', '<plug>(ts-config-files-nvim)' },
    { '<space>gf', '<plug>(ts-file-under-coursor)' },
  },
  cmd = 'Telescope',
  config = function()
    local u = require('pbogut.utils')
    local k = vim.keymap
    local actions = require('telescope.actions')
    local telescope = require('telescope')
    local actions_layout = require('telescope.actions.layout')
    local function builtin()
      return require('telescope.builtin')
    end

    k.set('n', '<plug>(telescope-live-grep)', function()
      builtin().live_grep()
    end)
    k.set('n', '<plug>(telescope-file-types)', function()
      builtin().filetypes()
    end)
    k.set('n', '<plug>(telescope-find-files)', function()
      builtin().find_files()
    end)
    k.set('n', '<plug>(telescope-find-files-no-ignore)', function()
      builtin().find_files({
        no_ignore = true,
      })
    end)
    k.set('n', '<plug>(telescope-find-files-with-hidden)', function()
      builtin().find_files({
        no_ignore = true,
        hidden = true,
      })
    end)
    k.set('n', '<plug>(telescope-buffers)', function()
      builtin().buffers()
    end)
    k.set('n', '<plug>(telescope-old-files-in-cwd)', function()
      builtin().oldfiles({ only_cwd = true })
    end)
    k.set('n', '<plug>(telescope-old-files)', function()
      builtin().oldfiles()
    end)
    k.set('n', '<plug>(ts-templates-list)', function()
      builtin().find_files({
        cwd = os.getenv('DOTFILES') .. '/config/nvim/templates',
      })
    end)
    k.set('n', '<plug>(ts-snippets-list)', function()
      builtin().find_files({
        cwd = os.getenv('DOTFILES') .. '/config/nvim',
        search_dirs = { 'lua/plugins/luasnip.lua', 'snippets', 'lua/plugins/luasnip' },
      })
    end)
    k.set('n', '<plug>(ts-config-files)', function()
      builtin().find_files({
        cwd = os.getenv('DOTFILES') .. '/..',
        no_ignore_parent = true,
        search_dirs = { 'dotfiles', 'dotfiles/config/nvim/lua/config' },
      })
    end)
    k.set('n', '<plug>(ts-config-files-nvim)', function()
      builtin().find_files({
        cwd = os.getenv('DOTFILES') .. '/config',
        no_ignore_parent = true,
        search_dirs = { 'nvim', 'nvim/lua/config' },
      })
    end)
    k.set('n', '<plug>(telescope-git-files)', function()
      builtin().git_status({
        attach_mappings = function(bufnr, map)
          -- disable stage change and use my default action
          map({ 'i', 'n' }, '<tab>', function()
            actions.toggle_selection(bufnr)
            actions.move_selection_worse(bufnr)
          end)
          return true
        end,
      })
    end)
    k.set('n', '<plug>(telescope-grep-string)', function()
      builtin().grep_string()
    end)
    k.set('n', '<plug>(ts-file-under-coursor)', function()
      local file = u.string_under_coursor()
      file = file:gsub('[~%.\\/]', ' ')
      builtin().grep_string({ search = u.trim_string(file) })
    end)

    local augroup = vim.api.nvim_create_augroup('x_telescope', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = 'TelescopePrompt',
      callback = function()
        -- some vim-rsi mappings for insert mode, otherwise overriden by my plugins
        vim.cmd([[
      inoremap <buffer>        <C-A> <C-O>^
      inoremap <buffer> <expr> <C-B> getline('.')=~'^\s*$'&&col('.')>strlen(getline('.'))?"0\<Lt>C-D>\<Lt>Esc>kJs":"\<Lt>Left>"
      inoremap <buffer> <expr> <C-E> col('.')>strlen(getline('.'))<bar><bar>pumvisible()?"\<Lt>C-E>":"\<Lt>End>"
      inoremap <buffer> <expr> <C-F> col('.')>strlen(getline('.'))?"\<Lt>C-F>":"\<Lt>Right>"
    ]])
      end,
    })

    telescope.setup({
      defaults = {
        path_display = function(_, path)
          local cwd = vim.fn.getcwd()
          local result = path
          if path:sub(1, #cwd) == cwd then
            result = '.' .. path:sub(#cwd + 1)
          end
          local parts = vim.split(result, '/')

          for i, part in pairs(parts) do
            if i ~= 1 and i ~= 2 and i ~= #parts and i ~= #parts - 1 and i ~= #parts - 2 then
              if part:len() > 6 then
                parts[i] = part:sub(1, 3) .. '…' .. part:sub(part:len() - 1)
              end
            end
          end

          return table.concat(parts, '/')
        end,
        sorting_strategy = 'ascending',
        layout_config = {
          prompt_position = 'top',
        },
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
        },
        mappings = {
          i = {
            ['<c-j>'] = actions.move_selection_next,
            ['<c-k>'] = actions.move_selection_previous,
            ['<c-s>'] = actions_layout.toggle_preview,

            ['<esc>'] = actions.close,

            ['<cr>'] = actions.select_default,
            ['<c-x>'] = actions.select_horizontal,
            ['<c-v>'] = actions.select_vertical,
            ['<c-t>'] = actions.select_tab,

            ['<c-u>'] = actions.preview_scrolling_up,
            ['<c-d>'] = actions.preview_scrolling_down,

            ['<PageUp>'] = actions.results_scrolling_up,
            ['<PageDown>'] = actions.results_scrolling_down,

            ['<tab>'] = actions.toggle_selection + actions.move_selection_worse,
            ['<s-tab>'] = actions.toggle_selection + actions.move_selection_better,
            ['<c-q>'] = function(id)
              local action_state = require('telescope.actions.state')
              local picker = action_state.get_current_picker(id)

              if #picker:get_multi_selection() > 0 then
                actions.send_selected_to_qflist(id)
                vim.cmd.Trouble('quickfix')
              else
                actions.send_to_qflist(id)
                vim.cmd.Trouble('quickfix')
              end
            end,
            ['<c-l>'] = actions.complete_tag,
            ['<c-_>'] = actions.which_key, -- keys from pressing <C-/>
          },
          n = {}, -- not a fan, hence <esc> above
        },
      },
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        },
        ['ui-select'] = {
          require('telescope.themes').get_dropdown({
            -- even more opts
          }),
        },
      },
    })
    require('telescope').load_extension('ui-select')
    require('telescope').load_extension('fzf_mru')
    require('telescope').load_extension('fzf')
  end,
}
