local u = require('utils')
local k = vim.keymap
local g = vim.g
local bo = vim.bo
local wo = vim.wo
local fn = vim.fn
local cmd = vim.cmd

-- dont mess with me!
g.no_plugin_maps = 1

k.set('n', '<bs>', ':Explore<cr>')
k.set(
  'n',
  '<c-s>',
  [[:echo synIDattr(synID(line('.'), col('.'), 1), "name")<cr>]]
)
-- macros helper (more like scratch pad)
k.set('n', '<space>em', ':tabnew ~/.vim/macros.vim<cr>')
k.set('n', '<space>sm', ':source ~/.vim/macros.vim<cr>')
-- nice to have
k.set('n', 'R', '^Da')
k.set('i', '<c-d>', '<del>')
k.set('c', '<c-d>', '<del>')
k.set('n', '<space><cr>', 'za')
k.set('v', '<space><cr>', 'zf')
k.set('n', '<space>tw', ':lua vim.wo.wrap = not vim.wo.wrap<cr>')
k.set('n', '<space>lq', ':copen<CR>')
k.set('n', '<space>ll', ':lopen<CR>')
-- Shift + J/K moves selected lines down/up in visual mode
k.set('v', 'J', [[:m '>+1<CR>gv=gv]])
k.set('v', 'K', [[:m '<-2<CR>gv=gv]])
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
k.set('s', 'p', '"_dP')
k.set('v', 'p', '"_dP')
k.set('n', '<space>', '"*')
k.set('v', '<space>', '"*')
-- more natural split (always right/below)
k.set('n', '<c-w>v', ':rightbelow vsplit<cr>')
k.set('n', '<c-w>s', ':rightbelow split<cr>')
k.set('n', '<c-w>V', ':vsplit<cr>')
k.set('n', '<c-w>S', ':split<cr>')
-- search helpers
k.set('n', '<esc>', ':set nohls<cr>')
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
    vim.cmd('let @/="' .. vim.fn.escape(term, [["\]]) .. '"')
    vim.cmd('set hls')
  end, 1)
end)
-- format file indentation
k.set('n', '<space>=', 'migg=G`i')
-- resize windows
k.set('', '<m-l>', ':vertical resize +1<cr>')
k.set('', '<m-h>', ':vertical resize -1<cr>')
k.set('', '<m-j>', ':resize +1<cr>')
k.set('', '<m-k>', ':resize -1<cr>')
-- terminal - normal mode
k.set('t', '<c-q>', [[<C-\><C-n>]])
-- diffmode
k.set('n', 'du', ':diffupdate<cr>') -- @todo check if should be silent?
k.set('n', 'dp', ':diffput<cr>')
k.set('n', 'dg', ':diffget<cr>')
-- create parent dir while saving file
k.set('n', '<space>w', function()
  fn.system('mkdir -p ' .. fn.expand('%:h'))
  local success, err = pcall(cmd, 'w!')
  if not success then
    cmd('SudaWrite')
  end
end)
-- open terminal
k.set('n', 'got', function()
  local path = fn.expand('%:p:h')
  cmd('belowright 20split')
  cmd('enew')
  fn.termopen('cd ' .. path .. ' && zsh')
  cmd('startinsert')
end)
k.set('n', 'goT', function()
  cmd('belowright 20split')
  cmd('enew ')
  fn.termopen('cd ' .. fn.getcwd() .. ' && zsh')
  cmd('startinsert')
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
k.set(
  'n',
  'yaf',
  [[:let @+=expand('%:p')<bar>echo 'Yanked: '.expand('%:p')<cr>]]
)
k.set(
  'n',
  'yif',
  [[:let @+=expand('%:t')<bar>echo 'Yanked: '.expand('%:t')<cr>]]
)
k.set(
  'n',
  'yrf',
  [[:let @+=expand('%:.')<bar>echo 'Yanked: '.expand('%:.')<cr>]]
)

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
  k.set(
    'n',
    '<space>s' .. keys,
    'y' .. motion .. ':s/<c-r>+//g<left><left>',
    { silent = false }
  )
  k.set(
    'n',
    '<space>%' .. keys,
    'y' .. motion .. ':%s/<c-r>+//g<left><left>',
    { silent = false }
  )
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
-- nnoremap <space>ev :tabnew $MYVIMRC<CR>
-- nnoremap <space>ez :tabnew ~/.zshrc<CR>
-- nnoremap <space>sv :source $MYVIMRC<CR>
-- mapping for local functions that use fzf

u.augroup('x_keybindings', {
  BufEnter = {
    {
      '*.keepass',
      function()
        k.set(
          'n',
          'gp',
          [[/^Password:<cr>:read !apg -m16 -n1 -MSNCL<cr>:%s/Password:.*\n/Password: /<cr><esc>]]
        )
      end,
    },
  },
  FileType = {
    {
      'netrw',
      function()
        k.set('n', '<bs>', '-', { remap = true, buffer = true })
        k.set('n', 'q', ':bdelete!<cr>', { buffer = true })
      end,
    },
    {
      'qf',
      function()
        k.set('n', 'o', '<cr>', { buffer = true })
        k.set('n', 'q', ':q', { buffer = true })
      end,
    },
    {
      'help',
      function()
        k.set('n', 'q', '<c-w>q', { buffer = true })
      end,
    },
  },
})
