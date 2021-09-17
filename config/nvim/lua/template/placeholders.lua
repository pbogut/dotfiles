local p = {
  base_name = {
    value = function()
      return vim.fn.expand('%:t:r')
    end
  },
  file_name = {
    value = function()
      return vim.fn.expand('%:t')
    end
  },
  current_date = {
    value = function()
      return os.date('%d/%m/%Y')
    end
  },
  _ = {
    value = function()
      return '[[coursor_position]]'
    end
  }
}

return p
