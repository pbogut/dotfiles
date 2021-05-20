" Automatically generated packer.nvim plugin loader code

if !has('nvim-0.5')
  echohl WarningMsg
  echom "Invalid Neovim version for packer.nvim!"
  echohl None
  finish
endif

packadd packer.nvim

try

lua << END
  local time
  local profile_info
  local should_profile = false
  if should_profile then
    local hrtime = vim.loop.hrtime
    profile_info = {}
    time = function(chunk, start)
      if start then
        profile_info[chunk] = hrtime()
      else
        profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
      end
    end
  else
    time = function(chunk, start) end
  end
  
local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end

  _G._packer = _G._packer or {}
  _G._packer.profile_output = results
end

time("Luarocks path setup", true)
local package_path_str = "/home/pbogut/.cache/nvim/packer_hererocks/2.0.5/share/lua/5.1/?.lua;/home/pbogut/.cache/nvim/packer_hererocks/2.0.5/share/lua/5.1/?/init.lua;/home/pbogut/.cache/nvim/packer_hererocks/2.0.5/lib/luarocks/rocks-5.1/?.lua;/home/pbogut/.cache/nvim/packer_hererocks/2.0.5/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/home/pbogut/.cache/nvim/packer_hererocks/2.0.5/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time("Luarocks path setup", false)
time("try_loadstring definition", true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s))
  if not success then
    print('Error running ' .. component .. ' for ' .. name)
    error(result)
  end
  return result
end

time("try_loadstring definition", false)
time("Defining packer_plugins", true)
_G.packer_plugins = {
  ReplaceWithRegister = {
    config = { 'require "plugins.replacewithregister"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/ReplaceWithRegister"
  },
  ale = {
    config = { 'require "plugins.ale"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/ale"
  },
  ["better-indent-support-for-php-with-html"] = {
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/better-indent-support-for-php-with-html"
  },
  ["cmdalias.vim"] = {
    config = { 'require "plugins.cmdalias_vim"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/cmdalias.vim"
  },
  ["compe-tabnine"] = {
    after_files = { "/home/pbogut/.local/share/nvim/site/pack/packer/opt/compe-tabnine/after/plugin/compe_tabnine.vim" },
    load_after = {},
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/compe-tabnine"
  },
  ["completion-treesitter"] = {
    load_after = {},
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/completion-treesitter"
  },
  ["echodoc.vim"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/echodoc.vim"
  },
  ["editorconfig-vim"] = {
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/editorconfig-vim"
  },
  ["elm-vim"] = {
    loaded = false,
    needs_bufread = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/elm-vim"
  },
  ["emmet-vim"] = {
    config = { 'require "plugins.emmet_vim"' },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/emmet-vim"
  },
  fzf = {
    after = { "fzf.vim" },
    only_config = true
  },
  ["fzf-mru.vim"] = {
    load_after = {},
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/fzf-mru.vim"
  },
  ["fzf.vim"] = {
    after = { "fzf-mru.vim" },
    load_after = {},
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/fzf.vim"
  },
  ["galaxyline.nvim"] = {
    config = { 'require "plugins.galaxyline_nvim"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/galaxyline.nvim"
  },
  ["git-messenger.vim"] = {
    config = { 'require "plugins.git_messanger"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/git-messenger.vim"
  },
  ["indent-blankline.nvim"] = {
    config = { 'require "plugins.indent_blankline"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/indent-blankline.nvim"
  },
  ["lsp-status.nvim"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/lsp-status.nvim"
  },
  ["matchit.vim"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/matchit.vim"
  },
  mdnav = {
    loaded = false,
    needs_bufread = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/mdnav"
  },
  neoformat = {
    commands = { "Neoformat" },
    config = { 'require "plugins.neoformat"' },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/neoformat"
  },
  ["neovim-colors-solarized-truecolor-only"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/neovim-colors-solarized-truecolor-only"
  },
  ["nvim-compe"] = {
    after = { "vim-dadbod-completion", "completion-treesitter", "compe-tabnine" },
    only_config = true
  },
  ["nvim-lspconfig"] = {
    config = { 'require "plugins.nvim_lsp"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/nvim-lspconfig"
  },
  ["nvim-treesitter"] = {
    after = { "completion-treesitter" },
    only_config = true
  },
  ["oceanic-next"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/oceanic-next"
  },
  ["packer.nvim"] = {
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/packer.nvim"
  },
  ["sideways.vim"] = {
    config = { 'require "plugins.sideways_vim"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/sideways.vim"
  },
  ["splitjoin.vim"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/splitjoin.vim"
  },
  ["suda.vim"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/suda.vim"
  },
  ["switch.vim"] = {
    config = { 'require "plugins.switch_vim"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/switch.vim"
  },
  tabular = {
    after_files = { "/home/pbogut/.local/share/nvim/site/pack/packer/opt/tabular/after/plugin/TabularMaps.vim" },
    commands = { "T", "Tabularize" },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/tabular"
  },
  ultisnips = {
    config = { 'require "plugins.ultisnips"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/ultisnips"
  },
  vdebug = {
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vdebug"
  },
  ["vim-abolish"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-abolish"
  },
  ["vim-autoswap"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-autoswap"
  },
  ["vim-bbye"] = {
    commands = { "Bdelete", "Bwipeout" },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-bbye"
  },
  ["vim-better-whitespace"] = {
    config = { 'require "plugins.vim_better_whitespace"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-better-whitespace"
  },
  ["vim-bookmarks"] = {
    config = { "vim.g.bookmark_save_per_working_dir = 1" },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-bookmarks"
  },
  ["vim-commentary"] = {
    config = { 'require "plugins.vim_commentary"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-commentary"
  },
  ["vim-dadbod"] = {
    after = { "vim-dadbod-ssh", "vim-dadbod-completion" },
    commands = { "DB" },
    config = { 'require "plugins.vim_dadbod"' },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-dadbod"
  },
  ["vim-dadbod-completion"] = {
    after_files = { "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-dadbod-completion/after/plugin/vim_dadbod_completion.vim" },
    load_after = {
      ["vim-dadbod"] = true
    },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-dadbod-completion"
  },
  ["vim-dadbod-ssh"] = {
    load_after = {
      ["vim-dadbod"] = true
    },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-dadbod-ssh"
  },
  ["vim-dirdiff"] = {
    commands = { "DirDiff" },
    config = { 'require "plugins.vim_dirdiff"' },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-dirdiff"
  },
  ["vim-dirvish"] = {
    after = { "vim-dirvish-git" },
    only_config = true
  },
  ["vim-dirvish-git"] = {
    load_after = {},
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-dirvish-git"
  },
  ["vim-elixir"] = {
    loaded = false,
    needs_bufread = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-elixir"
  },
  ["vim-elmper"] = {
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-elmper"
  },
  ["vim-eunuch"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-eunuch"
  },
  ["vim-fugitive"] = {
    config = { 'require "plugins.vim_fugitive"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-fugitive"
  },
  ["vim-git"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-git"
  },
  ["vim-gutentags"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-gutentags"
  },
  ["vim-illuminate"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-illuminate"
  },
  ["vim-openscad"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-openscad"
  },
  ["vim-polyglot"] = {
    loaded = false,
    needs_bufread = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-polyglot"
  },
  ["vim-projectroot"] = {
    config = { "      vim.g.rootmarkers = {'.projectroot', '.git', '.hg', '.svn', '.bzr',\n                           '_darcs', 'build.xml', 'composer.json', 'mix.exs'} " },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-projectroot"
  },
  ["vim-rails"] = {
    loaded = false,
    needs_bufread = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-rails"
  },
  ["vim-repeat"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-repeat"
  },
  ["vim-rsi"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-rsi"
  },
  ["vim-ruby"] = {
    loaded = false,
    needs_bufread = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-ruby"
  },
  ["vim-scriptease"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-scriptease"
  },
  ["vim-signify"] = {
    config = { 'require "plugins.vim_signify"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-signify"
  },
  ["vim-sneak"] = {
    config = { 'require "plugins.vim_sneak"' },
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-sneak"
  },
  ["vim-snippets"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-snippets"
  },
  ["vim-surround"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-surround"
  },
  ["vim-test"] = {
    commands = { "TestNearest", "TestFile", "TestSuite", "TestLast", "TestLast", "TestVisit" },
    config = { 'require "plugins.vim_test".config()' },
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-test"
  },
  ["vim-textobj-quotes"] = {
    loaded = false,
    needs_bufread = false,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-textobj-quotes"
  },
  ["vim-textobj-user"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-textobj-user"
  },
  ["vim-unimpaired"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-unimpaired"
  },
  ["vim-vsnip"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-vsnip"
  },
  ["vim-wakatime"] = {
    loaded = true,
    path = "/home/pbogut/.local/share/nvim/site/pack/packer/start/vim-wakatime"
  }
}

time("Defining packer_plugins", false)
-- Setup for: editorconfig-vim
time("Setup for editorconfig-vim", true)
require "plugins.editorconfig"
time("Setup for editorconfig-vim", false)
time("packadd for editorconfig-vim", true)
vim.cmd [[packadd editorconfig-vim]]
time("packadd for editorconfig-vim", false)
-- Setup for: vim-bbye
time("Setup for vim-bbye", true)
require "plugins.vim_bbye"
time("Setup for vim-bbye", false)
-- Setup for: vim-test
time("Setup for vim-test", true)
require "plugins.vim_test".setup()
time("Setup for vim-test", false)
-- Setup for: vim-polyglot
time("Setup for vim-polyglot", true)
require "plugins.polyglot"
time("Setup for vim-polyglot", false)
time("packadd for vim-polyglot", true)
vim.cmd [[packadd vim-polyglot]]
time("packadd for vim-polyglot", false)
-- Config for: sideways.vim
time("Config for sideways.vim", true)
require "plugins.sideways_vim"
time("Config for sideways.vim", false)
-- Config for: nvim-treesitter
time("Config for nvim-treesitter", true)
require "plugins.nvim_treesitter"
time("Config for nvim-treesitter", false)
-- Config for: ReplaceWithRegister
time("Config for ReplaceWithRegister", true)
require "plugins.replacewithregister"
time("Config for ReplaceWithRegister", false)
-- Config for: indent-blankline.nvim
time("Config for indent-blankline.nvim", true)
require "plugins.indent_blankline"
time("Config for indent-blankline.nvim", false)
-- Config for: ale
time("Config for ale", true)
require "plugins.ale"
time("Config for ale", false)
-- Config for: fzf
time("Config for fzf", true)
require "plugins.fzf"
time("Config for fzf", false)
-- Config for: galaxyline.nvim
time("Config for galaxyline.nvim", true)
require "plugins.galaxyline_nvim"
time("Config for galaxyline.nvim", false)
-- Config for: ultisnips
time("Config for ultisnips", true)
require "plugins.ultisnips"
time("Config for ultisnips", false)
-- Config for: switch.vim
time("Config for switch.vim", true)
require "plugins.switch_vim"
time("Config for switch.vim", false)
-- Config for: nvim-compe
time("Config for nvim-compe", true)
require "plugins.nvim_compe"
time("Config for nvim-compe", false)
-- Config for: vim-better-whitespace
time("Config for vim-better-whitespace", true)
require "plugins.vim_better_whitespace"
time("Config for vim-better-whitespace", false)
-- Config for: vim-commentary
time("Config for vim-commentary", true)
require "plugins.vim_commentary"
time("Config for vim-commentary", false)
-- Config for: git-messenger.vim
time("Config for git-messenger.vim", true)
require "plugins.git_messanger"
time("Config for git-messenger.vim", false)
-- Config for: vim-dirvish
time("Config for vim-dirvish", true)
require "plugins.vim_dirvish"
time("Config for vim-dirvish", false)
-- Config for: vim-fugitive
time("Config for vim-fugitive", true)
require "plugins.vim_fugitive"
time("Config for vim-fugitive", false)
-- Config for: nvim-lspconfig
time("Config for nvim-lspconfig", true)
require "plugins.nvim_lsp"
time("Config for nvim-lspconfig", false)
-- Config for: vim-signify
time("Config for vim-signify", true)
require "plugins.vim_signify"
time("Config for vim-signify", false)
-- Config for: vim-sneak
time("Config for vim-sneak", true)
require "plugins.vim_sneak"
time("Config for vim-sneak", false)
-- Config for: vim-projectroot
time("Config for vim-projectroot", true)
      vim.g.rootmarkers = {'.projectroot', '.git', '.hg', '.svn', '.bzr',
                           '_darcs', 'build.xml', 'composer.json', 'mix.exs'} 
time("Config for vim-projectroot", false)
-- Config for: cmdalias.vim
time("Config for cmdalias.vim", true)
require "plugins.cmdalias_vim"
time("Config for cmdalias.vim", false)
-- Config for: vim-bookmarks
time("Config for vim-bookmarks", true)
vim.g.bookmark_save_per_working_dir = 1
time("Config for vim-bookmarks", false)
-- Load plugins in order defined by `after`
time("Sequenced loading", true)
vim.cmd [[ packadd vim-dirvish-git ]]
vim.cmd [[ packadd fzf.vim ]]
vim.cmd [[ packadd fzf-mru.vim ]]
vim.cmd [[ packadd compe-tabnine ]]
vim.cmd [[ packadd completion-treesitter ]]
time("Sequenced loading", false)

-- Command lazy-loads
time("Defining lazy-load commands", true)
vim.cmd [[command! -nargs=* -range -bang -complete=file DB lua require("packer.load")({'vim-dadbod'}, { cmd = "DB", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file DirDiff lua require("packer.load")({'vim-dirdiff'}, { cmd = "DirDiff", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file TestSuite lua require("packer.load")({'vim-test'}, { cmd = "TestSuite", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Tabularize lua require("packer.load")({'tabular'}, { cmd = "Tabularize", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Bdelete lua require("packer.load")({'vim-bbye'}, { cmd = "Bdelete", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Neoformat lua require("packer.load")({'neoformat'}, { cmd = "Neoformat", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file TestLast lua require("packer.load")({'vim-test', 'vim-test'}, { cmd = "TestLast", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file T lua require("packer.load")({'tabular'}, { cmd = "T", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file Bwipeout lua require("packer.load")({'vim-bbye'}, { cmd = "Bwipeout", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file TestVisit lua require("packer.load")({'vim-test'}, { cmd = "TestVisit", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file TestNearest lua require("packer.load")({'vim-test'}, { cmd = "TestNearest", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
vim.cmd [[command! -nargs=* -range -bang -complete=file TestFile lua require("packer.load")({'vim-test'}, { cmd = "TestFile", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
time("Defining lazy-load commands", false)

vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time("Defining lazy-load filetype autocommands", true)
vim.cmd [[au FileType elm ++once lua require("packer.load")({'vim-elmper', 'elm-vim'}, { ft = "elm" }, _G.packer_plugins)]]
vim.cmd [[au FileType vue ++once lua require("packer.load")({'emmet-vim'}, { ft = "vue" }, _G.packer_plugins)]]
vim.cmd [[au FileType eelixir ++once lua require("packer.load")({'vim-elixir'}, { ft = "eelixir" }, _G.packer_plugins)]]
vim.cmd [[au FileType php ++once lua require("packer.load")({'emmet-vim', 'better-indent-support-for-php-with-html'}, { ft = "php" }, _G.packer_plugins)]]
vim.cmd [[au FileType markdown ++once lua require("packer.load")({'mdnav'}, { ft = "markdown" }, _G.packer_plugins)]]
vim.cmd [[au FileType elixir ++once lua require("packer.load")({'vim-elixir'}, { ft = "elixir" }, _G.packer_plugins)]]
vim.cmd [[au FileType html ++once lua require("packer.load")({'emmet-vim'}, { ft = "html" }, _G.packer_plugins)]]
vim.cmd [[au FileType blade ++once lua require("packer.load")({'emmet-vim'}, { ft = "blade" }, _G.packer_plugins)]]
vim.cmd [[au FileType ruby ++once lua require("packer.load")({'vim-rails', 'vim-ruby'}, { ft = "ruby" }, _G.packer_plugins)]]
time("Defining lazy-load filetype autocommands", false)
  -- Function lazy-loads
time("Defining lazy-load function autocommands", true)
vim.cmd[[au FuncUndefined db#url_complete ++once lua require("packer.load")({'vim-dadbod'}, {}, _G.packer_plugins)]]
time("Defining lazy-load function autocommands", false)
vim.cmd("augroup END")
vim.cmd [[augroup filetypedetect]]
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/elm-vim/ftdetect/elm.vim", true)
vim.cmd [[source /home/pbogut/.local/share/nvim/site/pack/packer/opt/elm-vim/ftdetect/elm.vim]]
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/elm-vim/ftdetect/elm.vim", false)
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-elixir/ftdetect/elixir.vim", true)
vim.cmd [[source /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-elixir/ftdetect/elixir.vim]]
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-elixir/ftdetect/elixir.vim", false)
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-ruby/ftdetect/ruby.vim", true)
vim.cmd [[source /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-ruby/ftdetect/ruby.vim]]
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-ruby/ftdetect/ruby.vim", false)
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-ruby/ftdetect/ruby_extra.vim", true)
vim.cmd [[source /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-ruby/ftdetect/ruby_extra.vim]]
time("Sourcing ftdetect script at: /home/pbogut/.local/share/nvim/site/pack/packer/opt/vim-ruby/ftdetect/ruby_extra.vim", false)
vim.cmd("augroup END")
if should_profile then save_profiles() end

END

catch
  echohl ErrorMsg
  echom "Error in packer_compiled: " .. v:exception
  echom "Please check your config for correctness"
  echohl None
endtry
