local command = vim.api.nvim_buf_create_user_command
local M = {}

M.config = function()
  local augroup = vim.api.nvim_create_augroup('x_openscad', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'openscad',
    callback = function()
      M.setup()
    end,
  })
  M.setup()
end

local function get_dst_file(src_file, dst_file)
  if dst_file then
    if not dst_file:match('%.stl$') then
      dst_file = dst_file .. '.stl'
    end
  else
    dst_file = vim.fn.substitute(src_file, [[\.[^\.]*$]], '.stl', '')
    if dst_file == src_file then
      vim.notify('Something is wrong...', vim.log.levels.ERROR)
      return
    end
  end

  return dst_file
end

local function progress(message)
  local progress_current = 0
  local progress_chars = {'.', '..',  '...'}
  return function()
      progress_current = progress_current + 1
      if progress_current > #progress_chars then
        progress_current =  1
      end
    vim.notify(message .. ' ' .. progress_chars[progress_current], vim.log.levels.INFO)
  end
end

M.setup = function()
  command(0, 'OpenScad', function()
    vim.cmd([[ silent! !openscad % > /dev/null 2>&1 &]])
  end, { nargs = 0, bang = false })

  command(0, 'OpenScadExport', function(opts)
    local src_file = vim.fn.expand('%')
    local dst_file = get_dst_file(src_file, opts.args[1])
    vim.notify('Exporting stl... ', vim.log.levels.INFO)
    vim.fn.jobstart({ 'openscad', '-o', dst_file, src_file }, {
      on_stdout = progress('Exporting stl'),
      on_stderr = progress('Exporting stl'),
      on_exit = function(_, code)
        if code == 0 then
          vim.notify('File exported: ' .. dst_file, vim.log.levels.INFO)
        else
          vim.notify('Error occured during export. Exit code: ' .. code, vim.log.levels.ERROR)
        end
      end,
    })
  end, { nargs = '?', bang = true })

  command(0, 'OpenScadSlice', function()
    local src_file = vim.fn.expand('%')
    local dst_file = '/tmp/openscad/' .. get_dst_file(src_file)
    vim.fn.mkdir(vim.fs.dirname(dst_file), 'p')
    vim.notify('Exporting stl... ', vim.log.levels.INFO)
    vim.fn.jobstart({ 'openscad', '-o', dst_file, src_file }, {
      on_stdout = progress('Exporting stl'),
      on_stderr = progress('Exporting stl'),
      on_exit = function(_, code)
        if code == 0 then
          vim.notify('File exported, opening slicer', vim.log.levels.INFO)
          vim.fn.jobstart({'prusa-slicer', dst_file})
        else
          vim.notify('Error occured during export. Exit code: ' .. code, vim.log.levels.ERROR)
        end
      end,
    })
  end, { nargs = 0, bang = true })
end

return M
