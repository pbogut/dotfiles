local function config(plugin)
  return function(plug, opts)
    local _, xcfg = pcall(require, 'plugins.' .. plugin)
    if type(xcfg) == 'table' and xcfg['config'] then
      return xcfg.config(plug, opts)
    end

    -- set mappings after plugin is loaded
    if plug.keys_after then
      local parser = require('lazy.core.handler.keys')
      for _, keymap in pairs(plug.keys_after) do
        local keys = parser.parse(keymap)
        vim.keymap.set(keys.mode, keys[1], keys[2], parser.opts(keys))
      end
    end
  end
end

local function init(plugin)
  local _, xcfg = pcall(require, 'plugins.' .. plugin)
  return function(plug, opts)
    if type(xcfg) == 'table' and xcfg['init'] then
      xcfg.init(plug, opts)
    end
  end
end

return {
  { 'nvim-lua/plenary.nvim', lazy = true },
  {
    'local/projector',
    config = config('projector'),
    dev = true,
  },
  { 'williamboman/mason.nvim', cmd = 'Mason', config = true },
  {
    'whoissethdaniel/mason-tool-installer.nvim',
    cmd = { 'MasonToolsInstall', 'MasonToolsUpdate' },
    config = config('mason_tool_installer'),
  },
  {
    'tpope/vim-abolish',
    keys = {
      { 'cr', '<plug>(abolish-coerce-word)', desc = 'Coerce word' },
    },
    init = function()
      vim.g.abolish_no_mappings = true
    end,
    cmd = { 'S', 'Abolish', 'Subvert' },
  },
  { 'tpope/vim-repeat' },
  {
    'tpope/vim-sleuth',
    config = function()
      vim.g.sleuth_no_filetype_indent_on = 1
    end,
  },
  { 'tpope/vim-fugitive', cmd = { 'Git', 'Gclog', 'Gllog' } },
  {
    'akinsho/toggleterm.nvim',
    keys = {
      { '<space>lg', '<cmd>LazyGitToggle<cr>', desc = 'LazyGitToggle' },
    },
    cmd = 'LazyGitToggle',
    config = config('toggleterm_nvim'),
  },
  { 'mbbill/undotree', cmd = { 'UndotreeToggle', 'UndotreeFocus', 'UndotreeShow', 'UndotreeHide' } },
  {
    'theprimeagen/harpoon',
    keys = {
      { 'ŋ', '<plug>(harpoon-toggle-menu)', desc = 'Harpoon toggle menu' },
      { '„', '<plug>(harpoon-add-file)', desc = 'Harpoon add file' },
      { 'æ', '<plug>(harpoon-nav-1)', desc = 'Harpoon nave file 1' },
      { 'ð', '<plug>(harpoon-nav-2)', desc = 'Harpoon nave file 2' },
      { 'ś', '<plug>(harpoon-nav-3)', desc = 'Harpoon nave file 3' },
      { 'ą', '<plug>(harpoon-nav-4)', desc = 'Harpoon nave file 4' },
      { 'h', '<plug>(harpoon-count)', desc = 'Harpoon count navigate' },
    },
    config = config('harpoon'),
  },
  {
    'theprimeagen/git-worktree.nvim',
    keys = {
      { '<space>gl', '<plug>(git-worktree-list)', desc = 'Git worktree list' },
      { '<space>gk', '<plug>(git-worktree-create)', desc = 'Create git worktree' },
    },
    config = config('git_worktree_nvim'),
  },
  { 'lambdalisue/suda.vim', cmd = 'SudaWrite' },
  { 'gioele/vim-autoswap', event = 'SwapExists' },
  {
    'kylechui/nvim-surround',
    opts = {
      keymaps = {
        -- disable default keymaps
        normal = '<plug>(nil)',
        normal_cur = '<plug>(nil)',
        delete = '<plug>(nil)',
        change = '<plug>(nil)',
        insert = '<plug>(nil)',
        insert_line = '<plug>(nil)',
        visual = '<plug>(nil)',
        visual_line = '<plug>(nil)',
        normal_line = '<plug>(nil)',
        normal_cur_line = '<plug>(nil)',
      },
    },
    keys = {
      { 'ys', '<plug>(nvim-surround-normal)', desc = 'Surround normal' },
      { 'yss', '<plug>(nvim-surround-normal-cur)', desc = 'Surround line' },
      { 'ds', '<plug>(nvim-surround-delete)', desc = 'Delete surround' },
      { 'cs', '<plug>(nvim-surround-change)', desc = 'Change surround' },
    },
    config = true,
  },
  { 'nvim-lualine/lualine.nvim', config = config('lualine_nvim') },
  { 'kyazdani42/nvim-web-devicons', config = config('nvim_web_devicons') },
  {
    'mfussenegger/nvim-dap',
    keys = {
      { '<space>dbc', '<plug>(dap-breakpoint-condition)' },
      { '<space>dbl', '<plug>(dap-breakpoint-log)' },
      { '<space>dd', '<plug>(dap-breakpoint-toggle)' },
      { '<space>dc', '<plug>(dap-continue)' },
      { '<space>ds', '<plug>(dap-close)' },
      { '<space>dl', '<plug>(dap-run-last)' },
      { '<space>dr', '<plug>(dap-repl-toggle)' },
      { '<space>dtc', '<plug>(dap-run-to-cursor)' },
      { '<space>di', '<plug>(dap-step-into)' },
      { '<space>dn', '<plug>(dap-step-over)' },
      { '<space>do', '<plug>(dap-step-out)' },
      { '<space>df', '<plug>(dap-breakpoint-list)' },
      { '<space>dx', '<plug>(dap-xdebug-toggle)' },
      { '<space>x', '<plug>(dap-xdebug-toggle)' },
      { '<space>k', '<plug>(dap-ui-hover)' },
    },
    dependencies = {
      { 'rcarriga/nvim-dap-ui', config = true },
    },
    config = config('nvim_dap'),
  },
  { 'lewis6991/gitsigns.nvim', event = 'BufReadPre', config = config('gitsigns_nvim') },
  {
    'ntpeters/vim-better-whitespace',
    event = { 'InsertEnter', 'BufReadPre' },
    config = config('vim_better_whitespace'),
  },
  {
    'andymass/vim-matchup',
    event = { 'BufWritePre', 'BufReadPre' },
    config = config('vim_matchup'),
    init = init('vim_matchup'),
    cond = true,
  },
  {
    'vim-test/vim-test',
    keys = {
      { '<space>tn', '<plug>(test-nearest)', desc = 'Test nearest' },
      { '<space>tf', '<plug>(test-file)', desc = 'Test file' },
      { '<space>ts', '<plug>(test-suite)', desc = 'Test suite' },
      { '<space>tl', '<plug>(test-last)', desc = 'Test last' },
      { '<space>tt', '<plug>(test-last)', desc = 'Test last' },
      { '<space>tv', '<plug>(test-visit)', desc = 'Test visit' },
    },
    cmd = { 'TestNearest', 'TestFile', 'TestSuite', 'TestLast', 'TestLast', 'TestVisit' },
    config = config('vim_test'),
    init = init('vim_test'),
  },
  { 'elmcast/elm-vim', ft = { 'elm' } },
  { 'elixir-lang/vim-elixir', ft = { 'elixir', 'eelixir' } },
  {
    'moll/vim-bbye',
    keys = {
      { '<c-w>d', '<cmd>silent! Bdelete<cr>' },
      { '<c-w>D', '<cmd>silent! Bdelete!<cr>' },
    },
    cmd = { 'Bdelete', 'Bwipeout' },
    config = config('vim_bbye'),
  },
  { 'will133/vim-dirdiff', cmd = 'DirDiff', config = config('vim_dirdiff') },
  { 'sindrets/diffview.nvim', cmd = { 'DiffviewOpen' } },
  {
    'AndrewRadev/switch.vim',
    keys = {
      { 'gs', '<plug>(Switch)', desc = 'Switch' },
    },
    init = function()
      vim.g.switch_mapping = ''
    end,
    config = config('switch_vim'),
  },
  {
    'wansmer/treesj',
    keys = {
      { 'gS', '<cmd>TSJSplit<cr>', silent = true },
      { 'gJ', '<cmd>TSJJoin<cr>', silent = true },
    },
    config = config('treesj'),
    cmd = { 'TSJSplit', 'TSJJoin' },
  },
  {
    'AndrewRadev/sideways.vim',
    keys = {
      { 'ga<', '<cmd>SidewaysLeft<cr>' },
      { 'ga>', '<cmd>SidewaysRight<cr>' },
      { 'aa', '<plug>SidewaysArgumentTextobjA', mode = { 'o', 'x' }, remap = true },
      { 'ia', '<plug>SidewaysArgumentTextobjI', mode = { 'o', 'x' }, remap = true },
    },
  },
  { 'vim-scripts/cmdalias.vim', event = 'CmdlineEnter', config = config('cmdalias_vim') },
  {
    'justinmk/vim-dirvish',
    keys = {
      { '<bs>', '<cmd>Dirvish %:p:h<cr>', desc = 'Dirvish' },
    },
    cmd = { 'Dirvish' },
    dependencies = 'kristijanhusak/vim-dirvish-git',
    config = config('vim_dirvish'),
    init = init('vim_dirvish'),
  },
  {
    'justinmk/vim-sneak',
    keys = {
      { 'f', '<plug>Sneak_f', mode = { 'n', 'x', 'o' }, remap = true, silent = false },
      { 'F', '<plug>Sneak_F', mode = { 'n', 'x', 'o' }, remap = true, silent = false },
      { 't', '<plug>Sneak_t', mode = { 'n', 'x', 'o' }, remap = true, silent = false },
      { 'T', '<plug>Sneak_T', mode = { 'n', 'x', 'o' }, remap = true, silent = false },
    },
    config = config('vim_sneak'),
  },
  {
    'ggandor/leap.nvim',
    keys = {
      { 's', '<pLug>(leap-forward-to)', mode = { 'n', 'x', 'o' }, silent = true },
      { 'S', '<plug>(leap-backward-to)', mode = { 'n', 'x', 'o' }, silent = true },
      { '<space>S', '<plug>(leap-everywhere)', mode = { 'n', 'x', 'o' }, silent = true },
    },
    config = config('nvim_leap'),
  },
  {
    'vim-scripts/ReplaceWithRegister',
    keys = {
      { 'cp', '<plug>ReplaceWithRegisterOperator', remap = true },
      { 'cp', '<Plug>ReplaceWithRegisterVisual', mode = 'x', remap = true },
      { 'cpp', '<Plug>ReplaceWithRegisterLine', remap = true },
      { 'cP', 'cp$', remap = true },
      { 'cp=', 'cpp==', remap = true },
    },
  },
  {
    'beloglazov/vim-textobj-quotes',
    keys = {
      { 'aq', '<plug>(textobj-quote-a)', mode = 'o' },
      { 'iq', '<plug>(textobj-quote-i)', mode = 'o' },
    },
    dependencies = 'kana/vim-textobj-user',
  },
  {
    'MattesGroeger/vim-bookmarks',
    event = 'BufReadPre',
    keys = {
      { 'mm', '<plug>BookmarToggle' },
      { 'mi', '<plug>BookmarAnnotate' },
      { '<space>fM', '<plug>(bookmarks-list)' },
    },
    config = config('vim_bookmarks'),
  },
  { 'rrethy/vim-illuminate', event = 'BufReadPre', cond = true },
  {
    'nvim-telescope/telescope.nvim',
    keys = {
      { '<space>fp', '<plug>(telescope-tmux-list-projects)' },
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
      { '<space>fc', '<plug>(ts-config-files)' },
      { '<space>fn', '<plug>(ts-config-files-nvim)' },
      { '<space>gf', '<plug>(ts-file-under-coursor)' },
    },
    cmd = 'Telescope',
    config = config('telescope_nvim'),
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
  },
  {
    'tpope/vim-dadbod',
    cmd = 'DB',
    keys = {
      { '<space>fd', '<plug>(dadbod-select-database)' },
    },
    config = config('vim_dadbod'),
    init = init('vim_dadbod'),
    fn = 'db#url_complete',
    dependencies = { 'pbogut/vim-dadbod-ssh' },
  },
  {
    'numtostr/comment.nvim',
    keys = {
      { '<c-_>', 'gcc<down>', remap = true },
      { '<c-/>', 'gcc<down>', remap = true },
      { '<c-_>', 'gc<down>', mode = 'v', remap = true },
      { '<c-/>', 'gc<down>', mode = 'v', remap = true },
    },
    dependencies = 'joosepalviste/nvim-ts-context-commentstring',
    config = config('comment_nvim'),
  },
  {
    'lommix/godot.nvim',
    config = 'require"godot".setup({})',
    cmd = {
      'GodotDebug',
      'GodotBreakAtCursor',
      'GodotStep',
      'GodotQuit',
      'GodotContinue',
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    config = config('nvim_treesitter_context'),
    cond = true,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufWritePre', 'BufReadPre', 'FileType' },
    build = function()
      vim.cmd.TSUpdate()
      vim.cmd.TSInstall('all')
    end,
    config = config('nvim_treesitter'),
    dependencies = {
      {
        'karanahlawat/tree-sitter-blade',
        build = 'tree-sitter generate && tree-sitter test',
        cond = true,
      },
    },
    cond = true,
  },
  { 'nvim-treesitter/playground', cmd = 'TSPlaygroundToggle' },

  {
    'rhysd/git-messenger.vim',
    keys = {
      { '<space>gm', '<plug>(git-messenger)', desc = 'Show git message' },
    },
  },
  {
    'simrat39/rust-tools.nvim',
    keys_after = {
      { '<space>rr', "<cmd>lua require('rust-tools').runnables.runnables()<cr>" },
    },
    config = config('rust_tools'),
    ft = { 'rust' },
  },
  {
    'epwalsh/obsidian.nvim',
    config = config('obsidian_nvim'),
    cmd = { 'Notes', 'NToday' },
    ft = { 'markdown' },
  },
  {
    'pbogut/magento2-ls',
    ft = { 'xml' },
    build = 'npm install && npm run build',
    config = function()
      require('magento2_ls').setup()
    end,
    enabled = function()
      return vim.fn.filereadable('bin/magento') == 1
    end,
    dev = true,
  },

  { 'nicwest/vim-http', cmd = { 'Http', 'HttpShowCurl', 'HttpShowRequest', 'HttpClean', 'HttpAuth' },
    keys = {
      { '<space>C', '<cmd>Http<cr>', desc = 'Run Http' },
    },
    config = function()
    vim.g.vim_http_split_vertically = 1
    vim.g.vim_http_tempbuffer = 1
    vim.g.vim_http_right_below = 1

    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('x_vim_http', { clear = true }),
      pattern = '*.response.*.http',
      callback = function()
        vim.keymap.set('n', 'q', '<cmd>bd<cr>', { buffer = true })
      end,
    })
  end },

  { 'kmonad/kmonad-vim', ft = { 'kbd' } },
  { 'sirtaj/vim-openscad', ft = { 'openscad' } },
  { 'tpope/vim-rails', ft = { 'ruby' } },
  { 'vim-ruby/vim-ruby', ft = { 'ruby' } },
  {
    'jackmort/chatgpt.nvim',
    keys = { { '<space>gpt', '<cmd>ChatGPT<cr>' } },
    config = config('chatgpt_nvim'),
    dependencies = {
      'muniftanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    cmd = { 'ChatGPT' },
  },
  {
    'l3mon4d3/luasnip',
    event = 'InsertEnter',
    dependencies = {
      'honza/vim-snippets',
    },
    config = config('luasnip'),
  },
  { 'zbirenbaum/copilot.lua', event = 'InsertEnter', config = config('copilot') },
  -- { 'github/copilot.vim', event = 'InsertEnter', config = config('copilot_vim') },
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    config = config('nvim_cmp'),
    dependencies = {
      { 'tzachar/cmp-tabnine', build = './install.sh', after = 'nvim-cmp' },
      'l3mon4d3/luasnip',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lua',
      'hrsh7th/cmp-emoji',
      'ray-x/cmp-treesitter',
      'onsails/lspkind-nvim',
      'saadparwaiz1/cmp_luasnip',
      --[[ 'zbirenbaum/copilot-cmp', ]]
      'kristijanhusak/vim-dadbod-completion',
    },
    cond = true,
  },
  {
    'folke/trouble.nvim',
    keys = {
      { '<space>ed', '<plug>(trouble-diagnostic-document)' },
      { '<space>ew', '<plug>(trouble-diagnostic-workspace)' },
      { '<space>lq', '<plug>(trouble-quickfix)' },
      { '<space>ll', '<plug>(trouble-loclist)' },
      { ']q', '<plug>(trouble-next-quickfix)' },
      { '[q', '<plug>(trouble-prev-quickfix)' },
      { ']l', '<plug>(trouble-next-loclist)' },
      { '[l', '<plug>(trouble-prev-loclist)' },
    },
    cmd = { 'Trouble', 'TroubleToggle', 'TroubleClose', 'TroubleRefresh' },
    config = config('trouble_nvim'),
  },
  {
    'stevearc/profile.nvim',
    config = function()
      local function toggle_profile()
        local prof = require('profile')
        if prof.is_recording() then
          prof.stop()
          vim.ui.input(
            { prompt = 'Save profile to:', completion = 'file', default = 'profile.json' },
            function(filename)
              if filename then
                prof.export(filename)
                vim.notify(string.format('Wrote %s', filename))
              end
            end
          )
        else
          prof.start('*')
        end
      end
      vim.keymap.set('', '<f1>', toggle_profile)
    end,
  },
  {
    'neovim/nvim-lspconfig',
    event = 'BufReadPre',
    dependencies = {
      { 'ray-x/lsp_signature.nvim', cond = true },
      { 'smiteshp/nvim-navic', cond = true },
    },
    config = config('nvim_lsp'),
  },
}
