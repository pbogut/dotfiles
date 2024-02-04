local u = require('pbogut.utils')
local k = vim.keymap
local g = vim.g
local bo = vim.bo
local wo = vim.wo
local fn = vim.fn
local cmd = vim.cmd

-- dont mess with me!
g.no_plugin_maps = 1

k.set('n', '<c-c>', function()
  if fn.confirm('Do you really want to quit with error?', 'Yes\nNo', 'No') == 1 then
    cmd.cquit()
  end
end)

k.set('n', '<space>fn', '<cmd>silent !wezterm-project ' .. os.getenv('DOTFILES') .. '/config/nvim "nvim-config"<cr>')
k.set('n', '<space>fc', '<cmd>silent !wezterm-project ' .. os.getenv('DOTFILES') .. ' "dotfiles"<cr>')
k.set('n', '$', '$zszH', { remap = true })
k.set('n', '^', '^zezH', { remap = true })
k.set('n', '<bs>', '<cmd>Explore<cr>')
k.set('n', '<c-s>', [[<cmd>echo synIDattr(synID(line('.'), col('.'), 1), "name")<cr>]])
-- macros helper (more like scratch pad)
k.set('n', '<space>em', '<cmd>tabnew ~/.vim/macros.lua<cr>')
k.set('n', '<space>sm', '<cmd>source ~/.vim/macros.lua<cr>')
-- nice to have
k.set('i', '<c-s>', '<esc>S')
k.set('i', '<c-d>', '<del>')
k.set('c', '<c-d>', '<del>')
k.set('n', '<space><cr>', 'za', { desc = 'Toggle fold' })
k.set('n', '<space><tab>', 'zA', { desc = 'Toggle fold recursively' })
k.set('v', '<space><cr>', 'zf', { desc = 'Create fold' })
k.set('n', '<space>tw', '<cmd>lua vim.wo.wrap = not vim.wo.wrap<cr>')
k.set('n', '<space>lq', '<cmd>copen<cr>')
k.set('n', '<space>ll', '<cmd>lopen<cr>')
-- center screen while scrolling
k.set('n', '<c-d>', '<c-d>zz')
k.set('n', '<c-u>', '<c-u>zz')
-- Shift + J/K moves selected lines down/up in visual mode
k.set('v', 'J', [[:m '>+1<cr>gv=gv]])
k.set('v', 'K', [[:m '<-2<cr>gv=gv]])
-- regex helpers
k.set('c', [[\\*]], [[\(.*\)]])
k.set('c', [[\\-]], [[\(.\{-}\)]])
-- command line navigation
k.set('c', '<c-k>', '<Up>')
k.set('c', '<c-j>', '<Down>')
-- remap delete to c-d because on hardware level Im sending del when c-d (ergodox)
k.set('n', '<del>', '<c-d>', { remap = true })
-- prevent pasting in visual from yanking seletion
k.set('', 'Y', 'y$')
k.set('v', 'p', '"_dP')
-- more natural split (always right/below)
k.set('n', '<c-w>v', '<cmd>rightbelow vsplit<cr>')
k.set('n', '<c-w>s', '<cmd>rightbelow split<cr>')
k.set('n', '<c-w>V', '<cmd>vsplit<cr>')
k.set('n', '<c-w>S', '<cmd>split<cr>')
k.set('n', '<c-w>O', '<cmd>tabonly<cr>')
-- search helpers
k.set('n', '<esc>', '<cmd>set nohls<cr>', { silent = true })
k.set('n', '*', ':set hls<cr>*')
k.set('n', '#', ':set hls<cr>#')
k.set('n', 'n', ':set hls<cr>n')
k.set('n', 'N', ':set hls<cr>N')
-- case insensitive search by default
k.set('n', '/', ':let @/=""<cr>:set hls<cr>/\\c', { silent = false })
k.set('n', '?', ':let @/=""<cr>:set hls<cr>?\\c', { silent = false })
-- highlight/search current word
-- (treat $word as word and word as $word to ease with PHP properties search)
k.set('n', '<space><space>', function()
  -- vim.fn.feedkeys('*``:set hls\n')
  vim.fn.feedkeys('*``')
  -- without defer it does not behave correctly
  vim.defer_fn(function()
    local term = vim.api.nvim_eval('@/')
    term, _ = term:gsub([[%$\=\zs]], [[%$]])
    term, _ = term:gsub('%$', [[%$\=\zs]])
    if not term:match([[^\<%$]]) then
      term, _ = term:gsub([[^\<]], [[\<%$\=\zs]])
    end
    cmd('let @/="' .. vim.fn.escape(term, [["\]]) .. '"')
    vim.o.hls = true
  end, 1)
end, { desc = 'Highlight word under cursor' })
-- format file indentation
k.set('n', '<space>=', 'migg=G`i')
-- tmux
k.set('n', '<c-q>', function()
  if os.getenv('TMUX') then
    os.execute('tmux detach')
  else
    cmd.quit()
  end
end)
-- terminal - normal mode
k.set('t', '<c-q>', [[<C-\><C-n>]])
-- shift space in wezterm produce wierd shit
k.set('t', '<s-space>', '<space>')
-- diffmode
k.set('n', 'du', '<cmd>diffupdate<cr>') -- @todo check if should be silent?
k.set('n', 'dp', '<cmd>diffput<cr>')
k.set('n', 'dg', '<cmd>diffget<cr>')
-- create parent dir while saving file
k.set('n', '<space>w', function()
  if vim.o.buftype == 'nofile' then
    vim.notify("Can't save nofile buffer", vim.log.levels.ERROR)
    return
  end
  fn.system('mkdir -p ' .. fn.expand('%:h'))
  local success, _ = pcall(cmd, 'w!')
  if not success then
    cmd.SudaWrite()
  end
end)
k.set('n', '<space>r', '') --prevent replace when using <space>r*
-- tmux
k.set('n', '<c-q>', function()
  if os.getenv('TMUX') then
    fn.system('tmux detach')
  else
    vim.cmd.quit()
  end
end)

k.set('n', '<space>mp', function()
  if os.getenv('TMUX') then
    return require('pbogut.tmuxctl').move_pane_to_project()
  end
end)
k.set('n', '<space>ti', function()
  if os.getenv('TMUX') then
    return require('pbogut.tmuxctl').show_pane('bottom', { height = 15, focus = true })
  end
  cmd('belowright 15split')
  cmd.enew()
  fn.termopen('cd ' .. fn.getcwd() .. ' && zsh')
  cmd.startinsert()
end)
k.set('n', '<space>to', function()
  local panes_count = vim.fn.system('tmux list-panes -F "#{pane_id}" | wc -l'):sub(1, -2)
  if panes_count == '1' then
    local tmux = require('pbogut.tmuxctl')
    return tmux.toggle_pane(tmux.get_last_pane() or 'bottom', { height = 15, focus = false })
  else
    return require('pbogut.tmuxctl').hide_all_panes()
  end
end)

k.set('n', '<space>;', function()
  local panes_count = vim.fn.system('tmux list-panes -F "#{pane_id}" | wc -l'):sub(1, -2)
  if panes_count == '1' then
    local tmux = require('pbogut.tmuxctl')
    return tmux.toggle_pane(tmux.get_last_pane() or 'bottom', { height = 15, focus = false })
  else
    return require('pbogut.tmuxctl').hide_all_panes()
  end
end)

k.set('n', '<space>:', function()
  local panes_count = vim.fn.system('tmux list-panes -F "#{pane_id}" | wc -l'):sub(1, -2)
  local tmux = require('pbogut.tmuxctl')
  return tmux.show_pane(tmux.get_last_pane() or 'bottom', { height = 15, focus = true })
end)

-- open terminal
-- k.set('n', '<space>lg', function()
--   vim.cmd('!lazygit-zellij open')
-- end)

k.set('n', 'goT', function()
  local path = fn.expand('%:p:h')
  if os.getenv('TMUX') then
    return require('pbogut.tmuxctl').toggle_pane('bottom' .. path, { height = 15, dir = path })
  end
  cmd('belowright 15split')
  cmd.enew()
  fn.termopen('cd ' .. path .. ' && zsh')
  cmd.startinsert()
end)
k.set('n', 'got', function()
  if os.getenv('TMUX') then
    return require('pbogut.tmuxctl').toggle_pane('bottom', { height = 15 })
  end
  cmd('belowright 15split')
  cmd.enew()
  fn.termopen('cd ' .. fn.getcwd() .. ' && zsh')
  cmd.startinsert()
end)
-- toggle spell dictionaires
k.set('n', '<space>ss', function()
  local get_next = false
  for _, spell_lang in pairs({ { true, 'en_gb' }, { true, 'pl' }, { false, 'en_gb' } }) do
    local spell = spell_lang[1]
    local lang = spell_lang[2]
    if get_next then
      wo.spell = spell
      bo.spelllang = lang
      if not spell then
        print('Disable spell checking')
      else
        print('Set spell to ' .. lang)
      end
      return
    end
    if spell == wo.spell and bo.spelllang == lang then
      get_next = true
    end
  end
  -- default if something is set up different
  print('Set spell to en_gb')
  bo.spelllang = 'en_gb'
  wo.spell = true
end)
-- yank file name
k.set('n', 'yaf', [[:let @+=expand('%:p')<bar>echo 'Yanked: '.expand('%:p')<cr>]])
k.set('n', 'yif', [[:let @+=expand('%:t')<bar>echo 'Yanked: '.expand('%:t')<cr>]])
k.set('n', 'yrf', [[:let @+=expand('%:.')<bar>echo 'Yanked: '.expand('%:.')<cr>]])

-- quick change and search for next occurrence, change can be repeated
-- by . N and n will search for the same selection, gn gN will select same
-- selection
for _, keys in pairs({ 'w', 'iw', 'aw', 'e', 'W', 'iW', 'aW' }) do
  local motion = keys
  if keys == 'w' then
    motion = 'e'
  end
  k.set('n', 'cg' .. keys, motion .. ':exe("let @/=@+")<bar><esc>cgn')
  k.set('n', 'cg' .. keys, 'y' .. motion .. ':exe("let @/=@+")<bar><esc>cgn')
  k.set('n', '<space>s' .. keys, 'y' .. motion .. ':s/<c-r>+//g<left><left>', { silent = false })
  k.set('n', '<space>%' .. keys, 'y' .. motion .. ':%s/<c-r>+//g<left><left>', { silent = false })
end

-- swap line navigation (for wraplines to be navigated by j/k)
for key1, key2 in pairs({ ['j'] = 'gj', ['k'] = 'gk' }) do
  for _, maptype in pairs({ 'n', 'x', 'o' }) do
    k.set(maptype, key1, key2)
    k.set(maptype, key2, key1)
  end
end

-- insert above
-- quick edit vimrc/zshrc and load vimrc bindings
-- nnoremap <space>ev :tabnew $MYVIMRC<cr>
-- nnoremap <space>ez :tabnew ~/.zshrc<cr>
-- nnoremap <space>sv :source $MYVIMRC<cr>
-- mapping for local functions that use fzf

local augroup = vim.api.nvim_create_augroup('x_keybindings', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup,
  pattern = '*.keepass',
  callback = function()
    k.set('n', 'gp', [[/^Password:<cr>:read !apg -m16 -n1 -MSNCL<cr>:%s/Password:.*\n/Password: /<cr><esc>]])
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'netrw',
  callback = function()
    k.set('n', '<bs>', '-', { remap = true, buffer = true })
    k.set('n', 'q', '<cmd>bdelete!<cr>', { buffer = true })
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'qf',
  callback = function()
    k.set('n', 'o', '<cr>', { buffer = true })
    k.set('n', 'q', '<cmd>q<cr>', { buffer = true })
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'help',
  callback = function()
    k.set('n', 'q', '<c-w>q', { buffer = true })
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'php',
  callback = function()
    k.set('n', 'yqn', function()
      local query = [[
        (namespace_definition (namespace_name) @namespace)
        [
          (class_declaration (name) @class)
          (interface_declaration (name) @interface)
        ]
      ]]

      local nodes = vim.treesitter.query.parse('php', query)
      local parser = vim.treesitter.get_parser(0, 'php')
      local root = parser:parse()[1]:root()

      local results = {}
      for _, node, _ in nodes:iter_captures(root) do
        results[#results + 1] = vim.treesitter.get_node_text(node, 0)
        if #results == 2 then
          break
        end
      end
      local fqn = table.concat(results, '\\')

      print('Yanked: ' .. fqn)
      vim.fn.setreg('+', fqn)
    end, { buffer = true })
  end,
})

-- vim-unimpaired mapping for pasting lines above and below
local function putline(how)
  local body = vim.fn.getreg(vim.v.register)
  local type = vim.fn.getregtype(vim.v.register)

  vim.fn.setreg(vim.v.register, body, 'l')
  vim.cmd.normal({ bang = true, args = { '"' .. vim.v.register .. how } })
  vim.fn.setreg(vim.v.register, body, type)
end

k.set('n', '[p', function()
  putline('[p')
end, { silent = true })
k.set('n', ']p', function()
  putline(']p')
end, { silent = true })

-- vim-rsi mappings (onle selected few)
vim.cmd([[
  inoremap        <C-A> <C-O>^
  cnoremap        <C-A> <Home>
  inoremap <expr> <C-B> getline('.')=~'^\s*$'&&col('.')>strlen(getline('.'))?"0\<Lt>C-D>\<Lt>Esc>kJs":"\<Lt>Left>"
  cnoremap        <C-B> <Left>
  inoremap <expr> <C-D> col('.')>strlen(getline('.'))?"\<Lt>C-D>":"\<Lt>Del>"
  cnoremap <expr> <C-D> getcmdpos()>strlen(getcmdline())?"\<Lt>C-D>":"\<Lt>Del>"
  inoremap <expr> <C-E> col('.')>strlen(getline('.'))<bar><bar>pumvisible()?"\<Lt>C-E>":"\<Lt>End>"
  inoremap <expr> <C-F> col('.')>strlen(getline('.'))?"\<Lt>C-F>":"\<Lt>Right>"
  cnoremap <expr> <C-F> getcmdpos()>strlen(getcmdline())?&cedit:"\<Lt>Right>"

  noremap!        <M-b> <S-Left>
  noremap!        <M-f> <S-Right>
  noremap!        <M-d> <C-O>dw
  cnoremap        <M-d> <S-Right><C-W>
  noremap!        <M-n> <Down>
  noremap!        <M-p> <Up>
  noremap!        <M-BS> <C-W>
  noremap!        <M-C-h> <C-W>
]])
