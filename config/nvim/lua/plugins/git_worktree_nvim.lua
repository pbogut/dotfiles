local tmux = require('tmuxctl')
local wt = require('git-worktree')
local k = vim.keymap
local Status = require('git-worktree.status')

local git = {}

function git.is_bare()
  local fwt = vim.split(vim.fn.system('git worktree list'), '\n')[1]
  if fwt:sub(#fwt - 5) == '(bare)' then
    return true, fwt:gsub('%(bare%)$', ''):gsub('[ ]*$', '')
  else
    return false, nil
  end
end

wt.switch_worktree = function(worktree_path)
  local is_bare, base_path = git.is_bare()
  if is_bare then
    worktree_path = base_path .. '/' .. worktree_path
  else
    worktree_path = vim.fn.getcwd() .. '/' .. worktree_path
  end

  tmux.switch_to_path(worktree_path)
end

Status.next_status = function(_) end -- this messages are annoying

k.set('n', '<plug>(git-worktree-list)', require('telescope').extensions['tmux-git-worktree'].git_worktrees)
k.set('n', '<plug>(git-worktree-create)', function()
  local branch_name = vim.fn.input('New worktree name > ')
  if branch_name:len() > 0 then
    wt.create_worktree(branch_name, branch_name)
  end
end)
