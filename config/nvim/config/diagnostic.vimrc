let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_virtual_text_prefix = ' '
let g:diagnostic_auto_popup_while_jump = 1
let g:diagnostic_insert_delay = 1
call sign_define("LspDiagnosticsErrorSign", {"text" : "", "texthl" : "LspDiagnosticsError"})
call sign_define("LspDiagnosticsWarningSign", {"text" : "", "texthl" : "LspDiagnosticsWarning"})
call sign_define("LspDiagnosticsInformationSign", {"text" : "", "texthl" : "LspDiagnosticsInformation"})
call sign_define("LspDiagnosticsHintSign", {"text" : "", "texthl" : "LspDiagnosticsHint"})

autocmd User after_vim_load
      \  highlight LspDiagnosticsError guibg=#073642 guifg=#dc322f gui=italic
      \| highlight LspDiagnosticsWarning guibg=#073642 guifg=#d33682 gui=italic
      \| highlight LspDiagnosticsInformation guibg=#073642 gui=italic
      \| highlight LspDiagnosticsHint guibg=#073642 gui=italic
