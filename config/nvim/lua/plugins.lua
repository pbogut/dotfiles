local execute = vim.api.nvim_command
local fn = vim.fn
local cmd = vim.cmd

local install_path = fn.stdpath('data') .. '/site/pack/packer/opt/packer.nvim'

local first_install = false

if fn.empty(fn.glob(install_path)) > 0 then
  execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
  first_install = true
end

execute('packadd packer.nvim')

-- reload and recompile this file (plugins.lua) after change
local ag_x_plugins_save = vim.api.nvim_create_augroup('x_plugins_save', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = ag_x_plugins_save,
  pattern = 'plugins.lua',
  callback = function()
    cmd.luafile(os.getenv('HOME') .. '/.config/nvim/lua/plugins.lua')
    cmd.PackerClean()
    cmd.PackerInstall()
    cmd.PackerCompile()
  end,
})
vim.api.nvim_create_autocmd('BufEnter', {
  group = ag_x_plugins_save,
  pattern = 'plugins.lua',
  callback = function()
    vim.bo.path = fn.stdpath('config') .. '/lua/plugins/'
  end,
})

local function config(plugin)
  return [[
    local _, xcfg = pcall(require, "plugins.]] .. plugin .. [[")
    if type(xcfg) == 'table' and xcfg['config'] then
      xcfg.config()
    end]]
end

local function setup(plugin)
  return [[
    local _, xcfg = pcall(require, "plugins.]] .. plugin .. [[")
    if type(xcfg) == 'table' and xcfg['setup'] then
      xcfg.setup()
    end]]
end

cmd.packadd('cfilter')
require('packer').startup({
  function(use)
    -- Packer can manage itself as an optional plugin
    use({ 'wbthomason/packer.nvim', opt = true })
    use({
      'lewis6991/impatient.nvim',
      config = [[
        _G.__luacache_config = {
          chunks = {
            enable = true,
            path = vim.fn.stdpath('cache')..'/luacache_chunks',
          },
          modpaths = {
            enable = true,
            path = vim.fn.stdpath('cache')..'/luacache_modpaths',
          }
        }
        require('impatient')
      ]],
    })

    use({ fn.stdpath('config') .. '/local/paranoic-backup', config = 'require"paranoic-backup"' })
    use({ fn.stdpath('config') .. '/local/projector', config = config('projector') })
    use({ fn.stdpath('config') .. '/local/actions', config = 'require"actions"' })
    use({ fn.stdpath('config') .. '/local/remotesync', config = 'require"remotesync"' })
    use({ fn.stdpath('config') .. '/local/echo_notify', config = 'require"echo_notify".setup({})' })
    use({ fn.stdpath('config') .. '/local/ripgrep', config = 'require"ripgrep"', after = 'telescope.nvim' })

    use({ 'williamboman/mason.nvim', config = 'require"mason".setup()' })
    use({ 'whoissethdaniel/mason-tool-installer.nvim', config = config('mason_tool_installer') })
    use({ 'pbogut/fzf-mru.vim', config = config('fzf_mru') })

    -- Github plugins
    use({ 'tpope/vim-scriptease' })
    use({ 'tpope/vim-eunuch' })
    use({ 'tpope/vim-abolish' }) -- coercion thingis
    use({ 'tpope/vim-repeat' })
    use({ 'tpope/vim-sleuth' })
    use({ 'tpope/vim-fugitive' })
    use({ 'akinsho/toggleterm.nvim', config = config('toggleterm_nvim') })
    use({ 'tpope/vim-rails', ft = { 'ruby' } })
    use({ 'vim-ruby/vim-ruby', ft = { 'ruby' } })
    use({ 'tpope/vim-unimpaired' })
    use({ 'mbbill/undotree' })
    use({ 'ThePrimeagen/harpoon', config = config('harpoon') })
    use({ 'ThePrimeagen/git-worktree.nvim', config = config('git_worktree_nvim') })
    use({ 'lambdalisue/suda.vim' })
    use({ 'gioele/vim-autoswap' })
    use({ 'kylechui/nvim-surround', config = config('nvim_surround') })
    use({ 'nvim-lualine/lualine.nvim', config = config('lualine_nvim') })
    use({ 'kyazdani42/nvim-web-devicons', config = config('nvim_web_devicons') })
    use({ 'mfussenegger/nvim-dap', config = config('nvim_dap') })
    use({ 'rcarriga/nvim-dap-ui', requires = { 'mfussenegger/nvim-dap' }, config = config('nvim_dap_ui') })
    use({ 'lewis6991/gitsigns.nvim', config = config('gitsigns_nvim') })
    use({ 'ntpeters/vim-better-whitespace', config = config('vim_better_whitespace') })
    use({ 'honza/vim-snippets' })
    use({
      'andymass/vim-matchup',
      config = config('vim_matchup'),
      setup = setup('vim_matchup'),
    })
    use({
      'vim-test/vim-test',
      cmd = { 'TestNearest', 'TestFile', 'TestSuite', 'TestLast', 'TestLast', 'TestVisit' },
      config = config('vim_test'),
      setup = setup('vim_test'),
    })
    use({ 'elmcast/elm-vim', ft = { 'elm' } })
    use({ 'elixir-lang/vim-elixir', ft = { 'elixir', 'eelixir' } })
    use({ 'moll/vim-bbye', cmd = { 'Bdelete', 'Bwipeout' }, setup = setup('vim_bbye') })
    use({ 'will133/vim-dirdiff', cmd = 'DirDiff', config = config('vim_dirdiff') })
    use({ 'sindrets/diffview.nvim' })
    use({
      'dbakker/vim-projectroot',
      config = [[
        vim.g.rootmarkers = {'.projectroot', '.git', '.hg', '.svn', '.bzr',
                             '_darcs', 'build.xml', 'composer.json', 'mix.exs'}
      ]],
    })
    use({ 'AndrewRadev/switch.vim', config = config('switch_vim') })
    use({ 'AndrewRadev/splitjoin.vim' })
    use({ 'AndrewRadev/sideways.vim', config = config('sideways_vim') })
    use({ 'vim-scripts/cmdalias.vim', config = config('cmdalias_vim') })
    use({ 'Shougo/echodoc.vim' })
    use({
      'justinmk/vim-dirvish',
      config = config('vim_dirvish'),
      requires = { 'kristijanhusak/vim-dirvish-git' },
    })
    use({ 'justinmk/vim-sneak', config = config('vim_sneak') })
    use({ 'vim-scripts/ReplaceWithRegister', config = config('replacewithregister') })
    use({ 'kana/vim-textobj-user' })
    use({ 'beloglazov/vim-textobj-quotes', after = 'vim-textobj-user' })
    use({ 'MattesGroeger/vim-bookmarks', config = config('vim_bookmarks') })
    use({ 'rrethy/vim-illuminate' })
    use({ 'lukas-reineke/indent-blankline.nvim', config = config('indent_blankline') })
    use({
      'nvim-telescope/telescope.nvim',
      config = config('telescope_nvim'),
      requires = { 'nvim-lua/plenary.nvim' },
    })
    use({ 'nvim-telescope/telescope-ui-select.nvim' })
    use({ 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' })
    use({
      'tpope/vim-dadbod',
      cmd = 'DB',
      config = config('vim_dadbod'),
      setup = setup('vim_dadbod'),
      fn = 'db#url_complete',
      requires = { 'pbogut/vim-dadbod-ssh' },
    })
    use({ 'joosepalviste/nvim-ts-context-commentstring' })
    use({ 'numtostr/comment.nvim', config = config('comment_nvim') })
    use({ 'frankier/neovim-colors-solarized-truecolor-only' })
    use({ 'sirtaj/vim-openscad', opt = false })
    use({ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate', config = config('nvim_treesitter') })
    use({ 'nvim-treesitter/playground' })
    use({ 'nvim-treesitter/nvim-treesitter-context', config = config('nvim_treesitter_context') })

    use({ 'rhysd/git-messenger.vim', config = config('git_messanger') })

    use({ 'simrat39/rust-tools.nvim', config = config('rust_tools') })

    -- completion
    use({ 'l3mon4d3/luasnip', after = 'projector', config = config('luasnip') })
    use({ 'tzachar/cmp-tabnine', run = './install.sh', after = 'nvim-cmp' })
    use({ 'zbirenbaum/copilot.lua', config = config('copilot'), after = { 'vim-rsi' } })
    use({
      'hrsh7th/nvim-cmp',
      after = { 'luasnip', 'projector', 'vim-rsi' },
      config = config('nvim_cmp'),
      setup = setup('nvim_cmp'),
      requires = {
        --[[ 'hrsh7th/cmp-buffer', ]]
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-emoji',
        'tzachar/cmp-tabnine',
        'ray-x/cmp-treesitter',
        'onsails/lspkind-nvim',
        'saadparwaiz1/cmp_luasnip',
        --[[ 'zbirenbaum/copilot-cmp', ]]
        'kristijanhusak/vim-dadbod-completion',
      },
    })

    -- lsp
    use({ 'ray-x/lsp_signature.nvim' })
    use({
      'jose-elias-alvarez/null-ls.nvim',
      config = config('null_ls_nvim'),
      requires = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    })
    use({ 'folke/trouble.nvim', config = config('trouble_nvim') })
    use({ 'neovim/nvim-lspconfig', config = config('nvim_lsp') })
    use({ 'smiteshp/nvim-gps', config = config('nvim_gps') })
    if vim.fn.filereadable((os.getenv('HOME') or '') .. '/.wakatime.cfg') > 0 then
      use({ 'wakatime/vim-wakatime' })
    end
    use({ 'activitywatch/aw-watcher-vim' })
  end,
})

if first_install then
  require('packages')
  cmd.InstallExternalPackages()
  cmd.PackerInstall()
  cmd.PackerCompile()
end
