local command = vim.api.nvim_create_user_command
local k = vim.keymap
local g = vim.g
local fn = vim.fn
local cmd = vim.cmd

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

g.dirvish_mode = [[:sort r /[^\/]$/]]
g.echodoc_enable_at_startup = 1

g.dirvish_git_indicators = {
  Modified = g.icon.changed,
  Staged = g.icon.added,
  Untracked = '☒',
  Renamed = g.icon.renamed,
  Unmerged = '═',
  Ignored = g.icon.ignored,
  Unknown = '?',
}

k.set('n', '\\won', '<plug>(dirvish_up)', { remap = true })
k.set('n', '<bs>', '<cmd>Dirvish %:p:h<cr>')

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('x_dirvish', { clear = true }),
  pattern = 'dirvish',
  callback = function()
    k.set('n', 'q', '<cmd>Bdelete<cr>', { buffer = true })
    k.set('n', '<bs>', '<plug>(dirvish_up)', { remap = false, buffer = true })
    k.set('n', 'H', '<plug>(dirvish_up)', { remap = false, buffer = true })
    k.set('n', 'cc', '<cmd>DirvishCopy<cr>', { buffer = true })
    k.set('n', 'rr', '<cmd>DirvishRename<cr>', { buffer = true })
    k.set('n', 'mm', '<cmd>DirvishMove<cr>', { buffer = true })
    k.set('n', 'dd', '<cmd>DirvishDelete<cr>', { buffer = true })
    k.set('n', 'K', '<cmd>DirvishCreate<cr>', { buffer = true })
    k.set('n', '/', [[/\ze[^\/]*[\/]\=$<Home>\c]], { silent = false, buffer = true })
    k.set('n', '?', [[?\ze[^\/]*[\/]\=$<Home>\c]], { silent = false, buffer = true })
    k.set('n', 'A', '<cmd>echo "Use K"<cr>', { buffer = true })
  end,
})

local function mkdir_parent(to)
  local dir = ''
  if to:match('%/$') then
    dir = fn.substitute(to, [[\(.*\)/[^/]\+/$]], [[\1]], '')
  else
    dir = fn.substitute(to, [[\(.*\)/[^/]\+]], [[\1]], '')
  end
  fn.system('mkdir -p ' .. fn.shellescape(dir))
end

local function dirvish_create()
  local from = fn.expand('%:p')
  fn.inputsave()
  local to = fn.input('create: ', from, 'file')
  fn.inputrestore()
  cmd.redraw({ bang = true })
  if not to or to == '' then
    return
  end
  local dir = ''
  if to:match('%/$') then
    dir = to
  else
    dir = fn.substitute(to, [[\(.*\)/[^/]\+]], [[\1]], '')
  end
  fn.system('mkdir -p ' .. fn.shellescape(dir))
  -- create empty file first
  fn.system('touch ' .. fn.shellescape(to))
  cmd.edit(fn.fnameescape(to))
end

local function dirvish_copy()
  local from = fn.getline('.')
  local extension = fn.substitute(from, [[.*/[^\.]*\(.\{-}\)$]], [[\1]], '')
  local move_cursor = fn.substitute(extension, '.', t('<left>'), 'g')
  fn.inputsave()
  local to = fn.input('!cp -r ' .. from .. ' -> ', from .. move_cursor, 'file')
  fn.inputrestore()
  cmd.redraw({ bang = true })
  if to and to ~= '' then
    mkdir_parent(to)
    fn.system('cp -r ' .. fn.shellescape(from) .. ' ' .. fn.shellescape(to))
    fn.append(fn.line('.') - 1, fn.fnameescape(to))
    fn.feedkeys('k')
  end
end

local function dirvish_move()
  local from = fn.getline('.')
  local extension = fn.substitute(from, [[.*/\(.\{-}\)$]], [[\1]], '')
  local move_cursor = fn.substitute(extension, '.', t('<left>'), 'g')
  fn.inputsave()
  local to = fn.input('!mv ' .. from .. ' -> ', from .. move_cursor, 'file')
  fn.inputrestore()
  cmd.redraw({ bang = true })
  if to and to ~= '' then
    fn.system('mv ' .. fn.shellescape(from) .. ' ' .. fn.shellescape(to))
    fn.setline('.', to)
  end
end

local function dirvish_rename()
  local suffix = ''
  local from = fn.getline('.')
  if from:match('%/$') then
    suffix = '/'
    from = from:gsub('(.*)%/', '%1')
  end
  local dir_name = fn.substitute(from, [[\(.*/\).\{-}$]], [[\1]], '')
  local file_name = fn.substitute(from, [[.*/\(.\{-}\)$]], [[\1]], '')
  local extension = fn.substitute(from, [[.*/[^\.]*\(.\{-}\)$]], [[\1]], '')
  local move_cursor = fn.substitute(extension, '.', t('<left>'), 'g')
  fn.inputsave()
  local to = fn.input('!mv ' .. from .. ' -> ' .. dir_name, file_name .. move_cursor, 'file')
  fn.inputrestore()
  cmd.redraw({ bang = true })
  if to and to ~= '' then
    fn.system('mv ' .. fn.shellescape(from) .. ' ' .. fn.shellescape(dir_name .. to))
    fn.setline('.', dir_name .. to .. suffix)
  end
end

local function dirvish_delete()
  local file = fn.getline('.')
  fn.inputsave()
  local confirm = fn.input('!rm -fr ' .. file .. ' // Are you sure? [yes|no]: ')
  fn.inputrestore()
  cmd.redraw({ bang = true })
  if confirm == 'yes' then
    fn.system('rm -fr ' .. vim.fn.shellescape(file))
    local cwd = vim.fn.getcwd()
    if file:sub(0, cwd:len()) then
      file = file:sub(cwd:len() + 2)
    end
    fn.execute('bd! ' .. fn.fnameescape(file))
    cmd.Dirvish('%')
  end
end

command('DirvishCreate', dirvish_create, {})
command('DirvishCopy', dirvish_copy, {})
command('DirvishMove', dirvish_move, {})
command('DirvishRename', dirvish_rename, {})
command('DirvishDelete', dirvish_delete, {})
