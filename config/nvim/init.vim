" basic settings
lua require('settings')

source ~/.config/nvim/config/perproject.vimrc

" autogroups
lua require('autogroups')

" Plug 'tpope/vim-dadbod'
autocmd User after_vim_load source ~/.config/nvim/config/dadbod.vimrc
" Plug 'w0rp/ale'
autocmd User after_plug_end source ~/.config/nvim/config/ale.vimrc

lua require('plugins')
" local plugins by me
lua require('projector')

doautocmd User after_plug_end
autocmd! User after_plug_end " clear after_plug_end command list

augroup after_load
  autocmd!
  autocmd VimEnter *
        \  doautocmd User after_vim_load
        \| autocmd! User after_vim_load " clear after_plug_end command list
augroup END

source ~/.config/nvim/config/terminal.vimrc

lua require('keymappings')
lua require('commands')

ProjectType laravel nnoremap <silent> <space>gf :call local#laravel#file_under_coursor()<cr>

let g:paranoic_backup_dir="~/.vim/backupfiles/"
