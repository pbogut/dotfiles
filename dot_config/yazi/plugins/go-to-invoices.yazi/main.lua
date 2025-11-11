return {
  entry = function()
    local home = os.getenv('HOME')
    local date = os.date('%Y/%m')
    local dest = home .. '/Documents/Axolit/Faktury/' .. date
    fs.create("dir_all", Url(dest))
    ya.emit('cd', { dest })
  end,
}
