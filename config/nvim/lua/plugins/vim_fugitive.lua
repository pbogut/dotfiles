local u = require('utils')
local cmd = vim.cmd
local fn = vim.fn

u.command('Gst', '0Gstatus')
u.command('Gl', '0Glog')

u.command('Grevert', function()
    cmd('Gread')
    cmd('noautocmd w')
    if fn.exists(':SignifyRefresh') then
        cmd('SignifyRefresh')
    end
end)

u.command('ShellGst', function()
  u.map('', 'q', '<c-w>q')
  u.map('n', 'q', '<c-w>q')
  cmd('Gst')
end)

u.augroup('x_fugitive', {
  FileType = {'fugitive', function()
      u.buf_map(0, '', 'q', '<c-w>q')
      u.buf_map(0, 'n', 'q', '<c-w>q')
      u.buf_map(0, 'n', 'au', [[:exec(':Git update-index --assume-unchanged ' .  substitute(getline('.'), '^[AM?]\s', '', ''))<cr>]], {silent = false})
  end}
})
