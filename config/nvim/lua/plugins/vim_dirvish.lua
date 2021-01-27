local u = require('utils')

u.augroup('x_dirvish', {
  FileType = {
    { 'dirvish',
      function()
        u.buf_map(0, 'n', 'q', '<c-w>q')
      end
    }
  }
})
