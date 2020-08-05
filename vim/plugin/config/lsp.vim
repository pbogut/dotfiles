" au User lsp_setup call lsp#register_server({
"      \ 'name': 'php-language-server',
"      \ 'cmd': {server_info->['php', expand('~/.config/nvim/plugged/php-language-server/bin/php-language-server.php')]},
"      \ 'whitelist': ['php'],
"      \ })

" au User lsp_setup call lsp#register_server({
"         \ 'name': 'tenkawa-php-language-server',
"         \ 'cmd': {server_info->[&shell, &shellcmdflag, 'php', expand('~/.config/nvim/plugged/tenkawa-php-language-server/bin/tenkawa.php')]},
"         \ 'whitelist': ['php'],
"         \ })

" if executable('golsp')
"     au User lsp_setup call lsp#register_server({
"         \ 'name': 'golsp',
"         \ 'cmd': {server_info->['golsp', '-mode', 'stdio']},
"         \ 'whitelist': ['go'],
"         \ })
" endif
"
"
