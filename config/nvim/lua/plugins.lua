local u = require('utils')
local execute = vim.api.nvim_command
local fn = vim.fn
local cmd = vim.cmd

local install_path = fn.stdpath('data')..'/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  execute('!git clone https://github.com/wbthomason/packer.nvim '..install_path)
  require('packages')
  cmd('InstallExternalPackages')
end

execute 'packadd packer.nvim'

-- reload and recompile this file (plugins.lua) after change
u.augroup('x_plugins_save', {BufWritePost = {'plugins.lua,packages.lua', function()
  package.loaded['packages'] = nil
  cmd('luafile ' .. os.getenv("HOME") .. '/.config/nvim/lua/plugins.lua')
  cmd('luafile ' .. os.getenv("HOME") .. '/.config/nvim/lua/packages.lua')
  cmd('PackerClean')
  cmd('PackerInstall')
  cmd('PackerCompile')
end}})

local function config(plugin)
  return [[
    local xcfg = require("plugins.]] .. plugin .. [[")
    if type(xcfg) == 'table' and xcfg['config'] then
      xcfg.config()
    end]]
end

local function setup(plugin)
  return [[
    local xcfg = require("plugins.]] .. plugin .. [[")
    if type(xcfg) == 'table' and xcfg['setup'] then
      xcfg.setup()
    end]]
end

return require('packer').startup({
  function()
    -- Packer can manage itself as an optional plugin
    use {'wbthomason/packer.nvim', opt = true}
    use {'editorconfig/editorconfig-vim', setup = setup('editorconfig')}
    use {'tpope/vim-scriptease'}
    use {'tpope/vim-eunuch'}
    use {'tpope/vim-rsi'}
    use {'tpope/vim-abolish'} -- coercion thingis
    use {'tpope/vim-commentary', config = config('vim_commentary')}
    use {'tpope/vim-surround'}
    use {'tpope/vim-repeat'}
    use {'tpope/vim-rails', ft = {'ruby'}}
    use {'vim-ruby/vim-ruby', ft = {'ruby'}}
    use {'tpope/vim-unimpaired'}
    use {'lambdalisue/suda.vim'}
    use {'gioele/vim-autoswap'}
    use {'glepnir/galaxyline.nvim', config = config('galaxyline_nvim')}
    use {'kyazdani42/nvim-web-devicons',
      config = config('nvim_web_devicons'),
    }
    use {'seblj/nvim-tabline',
      config = config('nvim_tabline'),
      requires = {'kyazdani42/nvim-web-devicons'},
    }
    use {'mfussenegger/nvim-dap', config = config('nvim_dap')}
    use {'mhinz/vim-signify', config = config('vim_signify')}
    use {'ludovicchabant/vim-gutentags'}
    use {'ntpeters/vim-better-whitespace', config = config('vim_better_whitespace')}
    use {'honza/vim-snippets'}
    use {'sbdchd/neoformat',
      cmd = 'Neoformat',
      config = config('neoformat'),
      setup = setup('neoformat'),
    }
    use {'k-takata/matchit.vim'}
    use {'vim-test/vim-test',
      cmd = {'TestNearest', 'TestFile', 'TestSuite',
             'TestLast', 'TestLast', 'TestVisit'},
      config = config('vim_test'),
      setup = setup('vim_test'),
    }
    use {'elmcast/elm-vim', ft = {'elm'}}
    use {'pbogut/vim-elmper', ft = {'elm'}}
    use {'elixir-lang/vim-elixir', ft = {'elixir', 'eelixir'}}
    use {'moll/vim-bbye', cmd = {'Bdelete', 'Bwipeout'}, setup = setup('vim_bbye')}
    use {'will133/vim-dirdiff', cmd = 'DirDiff', config = config('vim_dirdiff')}
    use {'dbakker/vim-projectroot',
      config = [[
        vim.g.rootmarkers = {'.projectroot', '.git', '.hg', '.svn', '.bzr',
                             '_darcs', 'build.xml', 'composer.json', 'mix.exs'}
      ]]
    }
    use {'AndrewRadev/switch.vim', config = config('switch_vim')}
    use {'AndrewRadev/splitjoin.vim'}
    use {'AndrewRadev/sideways.vim', config = config('sideways_vim')}
    use {'vim-scripts/cmdalias.vim', config = config('cmdalias_vim')}
    use {'Shougo/echodoc.vim'}
    use {'justinmk/vim-dirvish', config = config('vim_dirvish')}
    use {'justinmk/vim-sneak', config = config('vim_sneak')}
    use {'kristijanhusak/vim-dirvish-git', after = 'vim-dirvish'}
    use {'w0rp/ale', config = config('ale')}
    use {'chmp/mdnav', ft = {'markdown'}}
    use {'vim-scripts/ReplaceWithRegister', config = config('replacewithregister')}
    use {'kana/vim-textobj-user'}
    use {'beloglazov/vim-textobj-quotes', after = 'vim-textobj-user'}
    use {'MattesGroeger/vim-bookmarks',
      config = 'vim.g.bookmark_save_per_working_dir = 1'
    }
    use {'rrethy/vim-illuminate'}
    use {'lukas-reineke/indent-blankline.nvim', config = config('indent_blankline')}
    use {'junegunn/fzf', config = config('fzf')}
    use {'junegunn/fzf.vim', after = 'fzf'}
    use {'pbogut/fzf-mru.vim', after = 'fzf.vim', branch = 'lua'}
    use {'tpope/vim-dadbod',
      cmd = 'DB',
      config = config('vim_dadbod'),
      fn = 'db#url_complete',
    }
    use {'pbogut/vim-dadbod-ssh', after = 'vim-dadbod'}
    use {'frankier/neovim-colors-solarized-truecolor-only'}
    use {'kevinoid/vim-jsonc'}
    use {'sheerun/vim-polyglot', setup = setup('polyglot')}
    use {'sirtaj/vim-openscad', opt = false}
    use {'nvim-treesitter/nvim-treesitter',
      run = 'vim.cmd("TSUpdate")',
      config = config('nvim_treesitter')
    }

    -- git
    use {'timuntersberger/neogit',
      config = config('neogit'),
      setup = setup('neogit'),
      cmd = {'Neogit', 'Gst'},
      requires = {'nvim-lua/plenary.nvim'},
    }
    use {'rhysd/git-messenger.vim', config = config('git_messanger')}
    -- use {'nvim-lua/plenary.nvim'}

    -- completion
    use {'dcampos/nvim-snippy', config = config('nvim_snippy')}
    use {'hrsh7th/nvim-cmp',
      config = config('nvim_cmp'),
      requires = {
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-emoji',
        'quangnguyen30192/cmp-nvim-tags',
        'tzachar/cmp-tabnine',
        'ray-x/cmp-treesitter',
        'onsails/lspkind-nvim',
        'dcampos/cmp-snippy',
      }
    }
    use {'kristijanhusak/vim-dadbod-completion', after = {'nvim-cmp', 'vim-dadbod'}}
    use {'tzachar/cmp-tabnine', run = './install.sh', after = 'nvim-cmp'}

    -- lsp
    use {'neovim/nvim-lspconfig', config = config('nvim_lsp')}
    use {'nvim-lua/lsp-status.nvim'}
    if vim.fn.filereadable((os.getenv("HOME") or '') .. '/.wakatime.cfg') > 0 then
      use {'wakatime/vim-wakatime'}
    end

    require('packages').startup(use)
  end
})
