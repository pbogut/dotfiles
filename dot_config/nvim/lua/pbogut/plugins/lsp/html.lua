local opts = {
  filetypes = { 'html', 'php', 'blade', 'templ' },
  settings = {
    html = {
      validate = {
        scripts = true, -- some issues when mixed with PHP
      },
    },
  },
}

return opts
