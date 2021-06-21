local u = require('utils')
local execute = vim.api.nvim_command
local fn = vim.fn
local cmd = vim.cmd

local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  execute('!git clone https://github.com/wbthomason/packer.nvim '..install_path)
end

execute 'packadd packer.nvim'

-- reload and recompile this file (plugins.lua) after change
u.augroup('x_plugins_save', {BufWritePost = {'plugins.lua', function()
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
    use {'tpope/vim-fugitive', config = 'require "plugins.vim_fugitive"'}
    use {'tpope/vim-eunuch'}
    use {'tpope/vim-git'}
    use {'tpope/vim-rsi'}
    use {'tpope/vim-abolish'} -- coercion thingis
    use {'tpope/vim-commentary', config = 'require "plugins.vim_commentary"'}
    use {'tpope/vim-surround'}
    use {'tpope/vim-repeat'}
    use {'tpope/vim-rails', ft = {'ruby'}}
    use {'tpope/vim-unimpaired'}
    use {'lambdalisue/suda.vim'}
    use {'gioele/vim-autoswap'}
    use {'rhysd/git-messenger.vim', config = 'require "plugins.git_messanger"'}
    use {'glepnir/galaxyline.nvim', branch = 'main', config = 'require "plugins.galaxyline_nvim"'}
    use {'mhinz/vim-signify', config = 'require "plugins.vim_signify"'}
    use {'ludovicchabant/vim-gutentags'}
    use {'ntpeters/vim-better-whitespace', config = 'require "plugins.vim_better_whitespace"'}
    use {'honza/vim-snippets'}
    use {'mattn/emmet-vim',
      config = 'require "plugins.emmet_vim"',
      ft = {'php', 'html', 'blade', 'vue'},
    }
    use {'sirver/ultisnips', config = 'require "plugins.ultisnips"'}
    use {'sbdchd/neoformat', config = 'require "plugins.neoformat"', cmd = 'Neoformat'}
    use {'k-takata/matchit.vim'}
    use {'vim-test/vim-test',
      config = 'require "plugins.vim_test".config()',
      setup = 'require "plugins.vim_test".setup()',
      cmd = {'TestNearest', 'TestFile', 'TestSuite', 'TestLast', 'TestLast', 'TestVisit'},
    }
    use {'elmcast/elm-vim', ft = {'elm'}}
    use {'pbogut/vim-elmper', ft = {'elm'}}
    use {'elixir-lang/vim-elixir', ft = {'elixir', 'eelixir'}}
    use {'moll/vim-bbye', cmd = {'Bdelete', 'Bwipeout'}, setup = 'require "plugins.vim_bbye"'}
    use {'will133/vim-dirdiff', config = 'require "plugins.vim_dirdiff"', cmd = 'DirDiff'}
    use {'dbakker/vim-projectroot', config = [[
      vim.g.rootmarkers = {'.projectroot', '.git', '.hg', '.svn', '.bzr',
                           '_darcs', 'build.xml', 'composer.json', 'mix.exs'} ]]
    }
    use {'AndrewRadev/switch.vim', config = 'require "plugins.switch_vim"'}
    use {'AndrewRadev/splitjoin.vim'}
    use {'AndrewRadev/sideways.vim', config = 'require "plugins.sideways_vim"'}
    use {'vim-scripts/cmdalias.vim', config = 'require "plugins.cmdalias_vim"'}
    use {'Shougo/echodoc.vim'}
    use {'justinmk/vim-dirvish', config = 'require "plugins.vim_dirvish"'}
    use {'justinmk/vim-sneak', config = 'require "plugins.vim_sneak"'}
    use {'kristijanhusak/vim-dirvish-git', after = 'vim-dirvish'}
    use {'w0rp/ale', config = 'require "plugins.ale"'}
    use {'chmp/mdnav', ft = {'markdown'}}
    use {'vim-scripts/ReplaceWithRegister', config = 'require "plugins.replacewithregister"'}
    use {'kana/vim-textobj-user'}
    use {'beloglazov/vim-textobj-quotes', after = 'vim-textobj-user'}
    use {'MattesGroeger/vim-bookmarks', config = 'vim.g.bookmark_save_per_working_dir = 1'}
    use {'rrethy/vim-illuminate'}
    use {'lukas-reineke/indent-blankline.nvim', branch = 'lua',
                    config = 'require "plugins.indent_blankline"'}
    use {'junegunn/fzf' , config = 'require "plugins.fzf"'}
    use {'junegunn/fzf.vim', after = 'fzf'}
    use {'pbogut/fzf-mru.vim', after = 'fzf.vim', branch = 'lua'}
    use {'tpope/vim-dadbod', fn = 'db#url_complete', cmd = 'DB',
                             config = 'require "plugins.vim_dadbod"'}
    use {'pbogut/vim-dadbod-ssh', after = 'vim-dadbod'}
    use {'frankier/neovim-colors-solarized-truecolor-only'}

    use {'mhartington/oceanic-next'}

    use {'sheerun/vim-polyglot', setup = 'require "plugins.polyglot"'}
    use {'sirtaj/vim-openscad', opt = false}
    use {'nvim-treesitter/nvim-treesitter', run = 'vim.cmd("TSUpdate")',
         config = 'require "plugins.nvim_treesitter"'}

    -- use my patched version for is-keyward hack and sources sorting
    -- use {'pbogut/completion-nvim', config = 'require "plugins.completion_nvim"'}
    -- use {'kristijanhusak/vim-dadbod-completion', after = {'completion-nvim', 'vim-dadbod'}}
    -- use {'nvim-treesitter/completion-treesitter', after = {'nvim-treesitter', 'completion-nvim'}}
    -- use {'aca/completion-tabnine', run = './install.sh', after = 'completion-nvim'}
    -- use {'steelsojka/completion-buffers', after = 'completion-nvim'}

    -- nvim-compe - it has some performance issues with my setup, mostly with sql
    use {'hrsh7th/nvim-compe', config = 'require "plugins.nvim_compe"'}
    use {'kristijanhusak/vim-dadbod-completion', after = {'nvim-compe', 'vim-dadbod'}}
    use {'nvim-treesitter/completion-treesitter', after = {'nvim-treesitter', 'nvim-compe'}}
    use {'tzachar/compe-tabnine', run = './install.sh', after = 'nvim-compe'}

    -- lsp
    use {'neovim/nvim-lspconfig', config = 'require "plugins.nvim_lsp"'}
    use {'hrsh7th/vim-vsnip'}
    use {'nvim-lua/lsp-status.nvim'}
    -- candidates to get removed
    use {'vim-vdebug/vdebug', opt = true}
    use {'godlygeek/tabular', cmd = {'T', 'Tabularize'}}
    use {'captbaritone/better-indent-support-for-php-with-html', ft = {'php'}}
    -- use {'nvim-treesitter/completion-treesitter'}
    if vim.fn.filereadable((os.getenv("HOME") or '') .. '/.wakatime.cfg') > 0 then
      use {'wakatime/vim-wakatime'}
    end
  end
})
