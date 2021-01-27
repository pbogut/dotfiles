sign define LspDiagnosticsSignError text= texthl=LspDiagnosticsSignError linehl= numhl=
sign define LspDiagnosticsSignWarning text= texthl=LspDiagnosticsSignWarning linehl= numhl=
sign define LspDiagnosticsSignInformation text= texthl=LspDiagnosticsSignInformation linehl= numhl=
sign define LspDiagnosticsSignHint text= texthl=LspDiagnosticsSignHint linehl= numhl=

autocmd User after_vim_load
      \  highlight LspDiagnosticsSignError guibg=#073642 guifg=#dc322f
      \| highlight LspDiagnosticsSignWarning guibg=#073642 guifg=#d33682
      \| highlight LspDiagnosticsSignInformation guibg=#073642 guifg=#a68f46
      \| highlight LspDiagnosticsSignHint guibg=#073642 guifg=#9eab7d
      \| highlight LspDiagnosticsVirtualTextError guifg=#dc322f
      \| highlight LspDiagnosticsVirtualTextWarning guifg=#d33682
      \| highlight LspDiagnosticsVirtualTextInformation guifg=#a68f46
      \| highlight LspDiagnosticsVirtualTextHint guifg=#9eab7d
