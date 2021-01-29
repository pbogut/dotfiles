local u = require('utils')

-- macros helper (more like scratch pad)
u.map('n', '<space>em', ':tabnew ~/.vim/macros.vim<cr>')
u.map('n', '<space>sm', ':source ~/.vim/macros.vim<cr>')
-- nice to have
u.map('i', '<c-d>', '<del>')
u.map('c', '<c-d>', '<del>')
-- regex helpers
u.map('c', [[\\*]], [[\(.*\)]])
u.map('c', [[\\-]], [[\(.\{-}\)]])
-- command line navigation
u.map('c', '<M-k>', '<Up>')
u.map('c', '<M-j>', '<Down>')
-- prevent pasting in visual from yanking seletion
u.map('s', 'p', '"_dP')
u.map('v', 'p', '"_dP')
-- search helpers
u.map('n', '<esc>', ':set nohls<cr>')
u.map('n', '*', ':set hls<cr>*')
u.map('n', '#', ':set hls<cr>#')
-- case insensitive search by default
u.map('n', '/', ':let @/=""<cr>:set hls<cr>/\\c', { silent = false })
u.map('n', '?', ':let @/=""<cr>:set hls<cr>?\\c', { silent = false })
-- highlight/search curren word
u.map('n', '<space><space>', '*``:set hls<cr>')
-- format file indentation
u.map('n', '<space>=', 'migg=G`i')
-- trigger omnicompletion with c-space
u.map('n', '<C-Space>', 'a<c-x><c-o>')
u.map('i', '<C-Space>', '<c-x><c-o>')
-- resize windows
u.map('', '<M-l>', ':vertical resize +1<cr>')
u.map('', '<M-h>', ':vertical resize -1<cr>')
u.map('', '<M-j>', ':resize +1<cr>')
u.map('', '<M-k>', ':resize -1<cr>')
-- terminal - normal mode
u.map('t', '<c-q>', [[<C-\><C-n>]])
-- diffmode
u.map('n', 'du', ':diffupdate<cr>') -- @todo check if should be silent?


-- quick change and search for next occurrence, change can be repeated
-- by . N and n will search for the same selection, gn gN will select same
-- selection
for _, keys in pairs({ 'w', 'iw', 'aw', 'e', 'W', 'iW', 'aW' }) do
  local motion = keys
  if keys == 'w' then
    motion = 'e'
  end
  u.map('n', 'cg' .. keys, motion  .. ':exe("let @/=@+")<bar><esc>cgn')
  u.map('n', 'cg' .. keys, 'y' .. motion .. ':exe("let @/=@+")<bar><esc>cgn')
  u.map('n', '<space>s' .. keys, 'y' .. motion .. ':s/<c-r>+//g<left><left>', { silent = false })
  u.map('n', '<space>%' .. keys, 'y' .. motion .. ':%s/<c-r>+//g<left><left>', { silent = false })
end

-- insert above
-- imap <M-o> <esc>O
-- nmap <M-o> O
-- quick edit vimrc/zshrc and load vimrc bindings
-- nnoremap <space>ev :tabnew $MYVIMRC<CR>
-- nnoremap <space>ez :tabnew ~/.zshrc<CR>
-- nnoremap <space>sv :source $MYVIMRC<CR>
-- mapping for local functions that use fzf
u.map('n', '<space>et', ':call local#fzf#mytemplates()<CR>')
u.map('n', '<space>es', ':call local#fzf#mysnippets()<CR>')
u.map('n', '<space>ec', ':call local#fzf#vim_config()<cr>')


u.augroup('x_keybindings', {
  BufEnter = {
    { '*.keepass', function()
        u.map('n', 'gp', [[/^Password:<cr>:read !apg -m16 -n1 -MSNCL<cr>:%s/Password:.*\n/Password: /<cr><esc>]])
      end
    }
  },
  FileType = {
    { 'help', function()
        u.buf_map(0, 'n', 'q', '<c-w>q')
      end
    },
    { 'fugitive', function()
        u.buf_map(0, 'n', 'au', [[:exec(':Git update-index --assume-unchanged ' .  substitute(getline('.'), '^[AM?]\s', '', ''))<cr>]], { silent = false })
      end
    },
  }
})
