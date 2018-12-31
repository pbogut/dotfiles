au User lsp_setup call lsp#register_server({
     \ 'name': 'php-language-server',
     \ 'cmd': {server_info->['php', expand('~/.config/nvim/plugged/php-language-server/bin/php-language-server.php')]},
     \ 'whitelist': ['php'],
     \ })

if executable('golsp')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'golsp',
        \ 'cmd': {server_info->['golsp', '-mode', 'stdio']},
        \ 'whitelist': ['go'],
        \ })
endif
