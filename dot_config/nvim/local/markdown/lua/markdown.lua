local M = {}

M.cursor_on_markdown_link = function(line, col)
  local current_line = line or vim.api.nvim_get_current_line()
  local _, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
  cur_col = col or cur_col + 1 -- nvim_win_get_cursor returns 0-indexed column

  local find_boundaries = function(pattern)
    local open, close = current_line:find(pattern)
    while open ~= nil and close ~= nil do
      if open <= cur_col and cur_col <= close then
        return open, close
      end
      open, close = current_line:find(pattern, close + 1)
    end
  end

  -- wiki link
  local open, close = find_boundaries('%[%[.-%]%]')
  if open == nil or close == nil then
    -- markdown link
    open, close = find_boundaries('%[.-%]%(.-%)')
  end

  return open, close
end

M.follow = function()
  local open, close = M.cursor_on_markdown_link()
  local current_line = vim.api.nvim_get_current_line()

  if open == nil or close == nil then
    vim.notify('Cursor is not on a reference!')
    return false
  end

  local note_name = current_line:sub(open, close)
  if note_name:match('^%[.-%]%(.*%)$') then
    -- transform markdown link to wiki link
    note_name = note_name:gsub('^%[(.-)%]%((.*)%)$', '%2|%1')
  else
    -- wiki link
    note_name = note_name:sub(3, #note_name - 2)
  end

  local note_file_name = note_name

  if note_file_name:match('^[%a%d]*%:%/%/') then
    vim.fn.jobstart({ 'gio', 'open', note_file_name }, { detach = true })
    return true
  end

  if note_file_name:match('|[^%]]*') then
    note_file_name = note_file_name:sub(1, note_file_name:find('|') - 1)
  end

  local dir = vim.fn.expand('%:p'):gsub('/[^/]*$', '')
  local file = dir .. '/' .. note_file_name

  if vim.fn.filereadable(file) == 1 then
    vim.cmd.edit(file)
  else
    if not file:match('.*%.[a-z][a-z]?[a-z]?[a-z]?$') then
      file = file .. '.md'
    end
    vim.cmd.edit(file)
  end

  return true
end

M.setup = function()
  local command = vim.api.nvim_create_user_command

  command('MarkdownFollowLink', function()
    M.follow()
  end, {})

  command('Notes', function(opt)
    local builtin = require('telescope.builtin')
    builtin.find_files({
      cwd = os.getenv('HOME') .. '/Wiki/' .. opt.args,
      no_ignore_parent = true,
    })
  end, { nargs = '?' })

  command('Today', function()
    vim.cmd.edit('~/Wiki/daily_notes/' .. os.date('%Y-%m-%d') .. '.md')
  end, {})

  local augroup = vim.api.nvim_create_augroup('x_markdown', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'markdown',
    callback = function()
      vim.keymap.set('n', 'gf', function()
        if M.cursor_on_markdown_link() then
          return '<cmd>MarkdownFollowLink<cr>'
        else
          return 'gf'
        end
      end, { noremap = false, expr = true, buffer = 0 })
    end,
  })
end

return M
