local u = require('utils')
local fn = vim.fn
local cmd = vim.cmd

-- macros helper (more like scratch pad)
u.map('n', '<space>em', ':tabnew ~/.vim/macros.vim<cr>')
u.map('n', '<space>sm', ':source ~/.vim/macros.vim<cr>')
-- nice to have
u.map('n', 'R', '^Da')
u.map('i', '<c-d>', '<del>')
u.map('c', '<c-d>', '<del>')
u.map('i', '<m-cr>', '<cr><esc>O')
u.map('n', '<space><cr>', 'za')
u.map('v', '<space><cr>', 'zf')
u.map('n', '<space>tw', ':lua vim.wo.wrap = not vim.wo.wrap<cr>')
-- regex helpers
u.map('c', [[\\*]], [[\(.*\)]])
u.map('c', [[\\-]], [[\(.\{-}\)]])
-- command line navigation
u.map('c', '<m-k>', '<Up>')
u.map('c', '<m-j>', '<Down>')
-- remap delete to c-d because on hardware level Im sending del when c-d (ergodox)
u.map('n', '<del>', '<c-d>', {noremap = false})
-- prevent pasting in visual from yanking seletion
u.map('', 'Y', 'y$')
u.map('s', 'p', '"_dP')
u.map('v', 'p', '"_dP')
u.map('n', '<space>', '"*')
u.map('v', '<space>', '"*')
-- more natural split (always right/below)
u.map('n', '<c-w>v', ':rightbelow vsplit<cr>')
u.map('n', '<c-w>s', ':rightbelow split<cr>')
u.map('n', '<c-w>V', ':vsplit<cr>')
u.map('n', '<c-w>S', ':split<cr>')
-- search helpers
u.map('n', '<esc>', ':set nohls<cr>')
u.map('n', '*', ':set hls<cr>*')
u.map('n', '#', ':set hls<cr>#')
u.map('n', 'n', ':set hls<cr>n')
u.map('n', 'N', ':set hls<cr>N')
-- case insensitive search by default
u.map('n', '/', ':let @/=""<cr>:set hls<cr>/\\c', {silent = false})
u.map('n', '?', ':let @/=""<cr>:set hls<cr>?\\c', {silent = false})
-- highlight/search current word
-- (treat $word as word and word as $word to ease with PHP properties search)
u.map('n', '<space><space>', function()
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
u.map('n', '<space>=', 'migg=G`i')
-- trigger omnicompletion with c-space
u.map('n', '<C-Space>', 'a<c-x><c-o>')
u.map('i', '<C-Space>', '<c-x><c-o>')
-- resize windows
u.map('', '<m-l>', ':vertical resize +1<cr>')
u.map('', '<m-h>', ':vertical resize -1<cr>')
u.map('', '<m-j>', ':resize +1<cr>')
u.map('', '<m-k>', ':resize -1<cr>')
-- terminal - normal mode
u.map('t', '<c-q>', [[<C-\><C-n>]])
-- diffmode
u.map('n', 'du', ':diffupdate<cr>') -- @todo check if should be silent?
u.map('n', 'dp', ':diffput<cr>')
u.map('n', 'dg', ':diffget<cr>')
-- create parent dir while saving file
u.map('n', '<space>w', function()
  fn.system('mkdir -p ' .. fn.expand('%:h'))
  cmd('w!')
end)
-- yank file name
u.map('n', 'yaf', [[:let @+=expand('%:p')<bar>echo 'Yanked: '.expand('%:p')<cr>]])
u.map('n', 'yif', [[:let @+=expand('%:t')<bar>echo 'Yanked: '.expand('%:t')<cr>]])
u.map('n', 'yrf', [[:let @+=expand('%:.')<bar>echo 'Yanked: '.expand('%:.')<cr>]])

-- quick change and search for next occurrence, change can be repeated
-- by . N and n will search for the same selection, gn gN will select same
-- selection
for _, keys in pairs({'w', 'iw', 'aw', 'e', 'W', 'iW', 'aW'}) do
  local motion = keys
  if keys == 'w' then
    motion = 'e'
  end
  u.map('n', 'cg' .. keys, motion  .. ':exe("let @/=@+")<bar><esc>cgn')
  u.map('n', 'cg' .. keys, 'y' .. motion .. ':exe("let @/=@+")<bar><esc>cgn')
  u.map('n', '<space>s' .. keys, 'y' .. motion .. ':s/<c-r>+//g<left><left>', {silent = false})
  u.map('n', '<space>%' .. keys, 'y' .. motion .. ':%s/<c-r>+//g<left><left>', {silent = false})
end

-- swap line navigation (for wraplines to be navigated by j/k)
for key1, key2 in pairs({['j'] = 'gj', ['k'] = 'gk'}) do
  for _, maptype in pairs({'n', 'v', 'o'}) do
    u.map(maptype, key1, key2)
    u.map(maptype, key2, key1)
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
    {'*.keepass', function()
        u.map('n', 'gp', [[/^Password:<cr>:read !apg -m16 -n1 -MSNCL<cr>:%s/Password:.*\n/Password: /<cr><esc>]])
      end
    }
  },
  FileType = {
    {'qf', function()
        u.buf_map(0, 'n', 'o', '<cr>')
        u.buf_map(0, 'n', 'q', ':q')
      end
    },
    {'help', function()
        u.buf_map(0, 'n', 'q', '<c-w>q')
      end
    },
  }
})
