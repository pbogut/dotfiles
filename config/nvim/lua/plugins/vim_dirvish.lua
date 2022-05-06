local u = require('utils')
local k = vim.keymap
local t = u.termcodes
local g = vim.g
local fn = vim.fn
local cmd = vim.cmd

g.dirvish_mode = [[:sort r /[^\/]$/]]
g.echodoc_enable_at_startup = 1

g.dirvish_git_indicators = {
  Modified  = g.icon.changed,
  Staged    = g.icon.added,
  Untracked = '☒',
  Renamed   = g.icon.renamed,
  Unmerged  = '═',
  Ignored   = g.icon.ignored,
  Unknown   = '?'
}

k.set('n', '\\won', '<Plug>(dirvish_up)', { remap = true })
k.set('n', '<bs>', ':Dirvish %:p:h<cr>')

u.augroup('x_dirvish', {
  FileType = {
    {
      'dirvish',
      function()
        k.set('n', 'q', '<c-w>q')
        k.set('n', '<bs>', '<Plug>(dirvish_up)', { remap = false, buffer = true })
        k.set('n', 'H', '<Plug>(dirvish_up)', { remap = false, buffer = true })
        k.set('n', 'cc', ':DirvishCopy<cr>', { buffer = true })
        k.set('n', 'rr', ':DirvishRename<cr>', { buffer = true })
        k.set('n', 'mm', ':DirvishMove<cr>', { buffer = true })
        k.set('n', 'dd', ':DirvishDelete<cr>', { buffer = true })
        k.set('n', 'K', ':DirvishCreate<cr>', { buffer = true })
        k.set('n', '/', [[/\ze[^\/]*[\/]\=$<Home>\c]], { silent = false, buffer = true })
        k.set('n', '?', [[?\ze[^\/]*[\/]\=$<Home>\c]], { silent = false, buffer = true })
        k.set('n', 'A', ':echo "Use K"<cr>', { buffer = true })
      end
    }
  }
})

local function mkdir_parent(to)
  local dir = ''
  if to:match('%/$') then
    dir = fn.substitute(to, [[\(.*\)/[^/]\+/$]], [[\1]], '')
  else
    dir = fn.substitute(to, [[\(.*\)/[^/]\+]], [[\1]], '')
  end
  fn.system('mkdir -p ' .. dir)
end

local function dirvish_create()
  local from = fn.expand('%:p')
  fn.inputsave()
  local to = fn.input('create: ', from, 'file')
  fn.inputrestore()
  cmd('redraw!')
  if not to or to == '' then
    return
  end
  local dir = ''
  if to:match('%/$') then
    dir = to
  else
    dir = fn.substitute(to, [[\(.*\)/[^/]\+]], [[\1]], '')
  end
  fn.system('mkdir -p ' .. dir)
  -- create empty file first
  fn.system('touch ' .. to)
  cmd('e ' .. to)
end

local function dirvish_copy()
  local from = fn.getline('.')
  local extension = fn.substitute(from, [[.*/[^\.]*\(.\{-}\)$]], [[\1]], '')
  local move_cursor = fn.substitute(extension, '.', t'<left>', 'g')
  fn.inputsave()
  local to = fn.input('!cp -r ' .. from .. ' -> ', from .. move_cursor, 'file')
  fn.inputrestore()
  cmd('redraw!')
  if to and to ~= '' then
    mkdir_parent(to)
    fn.system('cp -r ' .. from .. ' ' .. to)
    fn.append(fn.line('.') - 1, to)
    fn.feedkeys('k')
  end
end

local function dirvish_move()
  local from = fn.getline('.')
  local extension = fn.substitute(from, [[.*/\(.\{-}\)$]], [[\1]], '')
  local move_cursor = fn.substitute(extension, '.', t'<left>', 'g')
  fn.inputsave()
  local to = fn.input('!mv ' .. from .. ' -> ', from .. move_cursor, 'file')
  fn.inputrestore()
  cmd('redraw!')
  if to and to ~= '' then
    fn.system('mv ' .. from .. ' ' .. to)
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
  local move_cursor = fn.substitute(extension, '.', t'<left>', 'g')
  fn.inputsave()
  local to = fn.input('!mv ' .. from .. ' -> ' .. dir_name, file_name .. move_cursor, 'file')
  fn.inputrestore()
  cmd('redraw!')
  if to and to ~= '' then
    fn.system('mv ' .. from .. ' ' .. dir_name .. to)
    fn.setline('.', dir_name .. to .. suffix)
  end
end

local function dirvish_delete()
  local file = fn.getline('.')
  fn.inputsave()
  local confirm = fn.input('!rm -fr ' .. file .. ' // Are you sure? [yes|no]: ')
  fn.inputrestore()
  cmd('redraw!')
  if confirm == 'yes' then
    fn.system('rm -fr ' .. file)
    fn.system('bd! ' .. file)
    cmd('Dirvish %')
  end
end

u.command('DirvishCreate', dirvish_create)
u.command('DirvishCopy', dirvish_copy)
u.command('DirvishMove', dirvish_move)
u.command('DirvishRename', dirvish_rename)
u.command('DirvishDelete', dirvish_delete)
