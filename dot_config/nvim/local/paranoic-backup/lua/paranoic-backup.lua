local Job = require('plenary.job')
local backup_dir = vim.fn.stdpath('data') .. '/paranoic_backup'

local function setup(opts)
  backup_dir = opts.dir or backup_dir
end

local function make_backup()
  local esc_backup_dir = vim.fn.fnameescape(backup_dir)

  if vim.fn.isdirectory(backup_dir) ~= 1 then
    -- create dir if not exists
    vim.fn.system('mkdir -p ' .. esc_backup_dir)
  end
  if vim.fn.isdirectory(backup_dir .. '/.git') ~= 1 then
    -- create git repo in the directory
    vim.fn.system('cd ' .. esc_backup_dir .. ' && git init')
  end

  local backup_file_dir = backup_dir .. vim.fn.expand('%:p:h')
  local file_name = vim.fn.expand('%:t')
  local timestamp = vim.fn.strftime('%Y-%m-%d %H:%M:%S')
  local backup_file_full_path = backup_file_dir .. '/' .. file_name
  local short = #backup_file_full_path > 30 and '...' .. backup_file_full_path:sub(-27, -1) or backup_file_full_path
  local message = timestamp .. ' ' .. short

  local orig_file = vim.fn.expand('%:p')

  if file_name == 'COMMIT_EDITMSG' then
    return
  end
  if file_name == 'git-rebase-todo' then
    return
  end

  local mkdir = Job:new({
    command = 'mkdir',
    args = { '-p', backup_file_dir },
    cwd = backup_dir,
  })
  local cp = Job:new({
    command = 'cp',
    args = { orig_file, backup_file_dir },
    cwd = backup_dir,
  })
  local git_add = Job:new({
    command = 'git',
    args = { 'add', backup_file_full_path },
    cwd = backup_dir,
  })
  local git_commit = Job:new({
    command = 'git',
    args = { 'commit', backup_file_full_path, '-m', message },
    cwd = backup_dir,
  })

  mkdir:and_then_on_success(cp)
  cp:and_then_on_success(git_add)
  git_add:and_then_on_success(git_commit)
  mkdir:start()
end

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('paranoic_backup', { clear = true }),
  callback = make_backup,
})

return {
  setup = setup,
}
