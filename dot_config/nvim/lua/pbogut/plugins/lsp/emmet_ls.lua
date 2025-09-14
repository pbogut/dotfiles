local opts = {
  cmd = { 'node', gitpac_path('pbogut/emmet-ls/out/server.js'), '--stdio' },
  filetypes = { 'xml', 'php', 'html', 'blade', 'vue', 'eelixir', 'css' },
  settings = {
    html_filetypes = { 'xml', 'html', 'php' },
    css_filetypes = { 'css', 'html', 'php' },
  },
}

return opts
