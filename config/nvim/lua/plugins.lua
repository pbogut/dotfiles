local U = require('utils')
local execute = vim.api.nvim_command
local fn = vim.fn
local cmd = vim.cmd

local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  execute('!git clone https://github.com/wbthomason/packer.nvim '..install_path)
end

execute 'packadd packer.nvim'

-- reload and recompile this file (plugins.lua) after change
U.augroup('x_plugins_save', {BufWritePost = {'plugins.lua', function()
  cmd('luafile ' .. os.getenv("HOME") .. '/.config/nvim/lua/plugins.lua')
  cmd('PackerClean')
  cmd('PackerInstall')
  cmd('PackerCompile')
end}})

return require('packer').startup({
  function()
    -- Packer can manage itself as an optional plugin
    use {'wbthomason/packer.nvim', opt = true}
    use {'editorconfig/editorconfig-vim', setup = 'require "plugins.editorconfig"'}
    use {'vim-ruby/vim-ruby', ft = {'ruby'}}
    use {'tpope/vim-scriptease'}
    use {'tpope/vim-dadbod'}
    use {'tpope/vim-fugitive'}
    use {'tpope/vim-eunuch'}
    use {'tpope/vim-git'}
    use {'tpope/vim-commentary', config = 'require "plugins.vim_commentary"'}
    use {'tpope/vim-surround'}
    use {'tpope/vim-repeat'}
    use {'tpope/vim-rails', ft = {'ruby'}}
    use {'tpope/vim-unimpaired'}
    use {'tpope/vim-projectionist', config = 'require "plugins.projectionist"'}
    use {'rhysd/git-messenger.vim'}
    use {'vim-airline/vim-airline', config = 'require "plugins.vim_airline"'}
    use {'vim-airline/vim-airline-themes', after = 'vim-airline'}
    use {'mhinz/vim-signify'}
    use {'ludovicchabant/vim-gutentags'}
    use {'ntpeters/vim-better-whitespace', config = 'vim.g.strip_whitespace_on_save = 0'}
    use {'honza/vim-snippets'}
    use {'mattn/emmet-vim', ft = {'php', 'html', 'blade', 'vue'},
                            config = 'require "plugins.emmet_vim"'}
    use {'sirver/ultisnips', config = 'require "plugins.ultisnips"'}
    use {'sbdchd/neoformat', config = 'require "plugins.neoformat"', cmd = 'Neoformat'}
    use {'k-takata/matchit.vim'}
    use {'vim-test/vim-test', cmd = {'TestNearest', 'TestFile', 'TestSuite',
                                     'TestLast', 'TestLast', 'TestVisit'}}
    use {'elmcast/elm-vim', ft = {'elm'}}
    use {'pbogut/vim-elmper', ft = {'elm'}}
    use {'elixir-lang/vim-elixir', ft = {'elixir', 'eelixir'}}
    use {'moll/vim-bbye', cmd = {'Bdelete'}}
    use {'will133/vim-dirdiff', config = 'require "plugins.vim_dirdiff"', cmd = 'DirDiff'}
    use {'dbakker/vim-projectroot'}
    use {'AndrewRadev/switch.vim'}
    use {'AndrewRadev/splitjoin.vim'}
    use {'AndrewRadev/sideways.vim'}
    use {'vim-scripts/cmdalias.vim'}
    use {'Shougo/echodoc.vim'}
    use {'justinmk/vim-dirvish', config = 'require "plugins.vim_dirvish"'}
    use {'kristijanhusak/vim-dirvish-git', after = 'vim-dirvish'}
    use {'w0rp/ale'}
    use {'chmp/mdnav', ft = {'md'}}
    use {'samoshkin/vim-mergetool'}
    use {'vim-scripts/ReplaceWithRegister'}
    use {'kana/vim-textobj-user'}
    use {'beloglazov/vim-textobj-quotes', after = 'vim-textobj-user'}
    use {'MattesGroeger/vim-bookmarks'}
    use {'rrethy/vim-illuminate'}
    use {'junegunn/fzf' , config = 'require "plugins.fzf"'}
    use {'junegunn/fzf.vim', after = 'fzf'}
    use {'pbogut/fzf-mru.vim', after = 'fzf.vim'}
    use {'frankier/neovim-colors-solarized-truecolor-only'}
    use {'sheerun/vim-polyglot', setup = 'require "plugins.polyglot"'}
    use {'sirtaj/vim-openscad', opt = false}
    use {'/home/pbogut/Projects/github.com/pbogut/simple-fold'}
    -- lsp
    use {'neovim/nvim-lspconfig', config = 'require "plugins.nvim_lsp"'}
    use {'nvim-lua/completion-nvim', config = 'require "plugins.completion_nvim"'}
    use {'steelsojka/completion-buffers', after = 'completion-nvim'}
    -- candidates to get removed
    use {'vim-vdebug/vdebug', opt = true}
    use {'godlygeek/tabular', cmd = {'T', 'Tabularize'}}
    use {'captbaritone/better-indent-support-for-php-with-html', ft = {'php'}}
    -- use {'tpope/vim-rsi'}
    -- use {'MarcWeber/vim-addon-mw-utils'}
    -- use {'gioele/vim-autoswap'}
    -- use {'joereynolds/gtags-scope'}
    -- use {'prabirshrestha/async.vim'} -- possibly used by vim-arilines ?
    -- use {'kana/vim-operator-user'}
    -- use {'slashmili/alchemist.vim', ft = {'elixir', 'eelixir'}}
    -- use {'powerman/vim-plugin-AnsiEsc', ft = {'elixir', 'eelixir'}}

    use {'wakatime/vim-wakatime', cond = function()
      local f = os.getenv("HOME") .. '/.wakatime.cfg'
      return vim.fn.filereadable(f) > 0
    end}
  end
})
