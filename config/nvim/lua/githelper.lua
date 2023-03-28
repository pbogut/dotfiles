local M = {}

function M.is_bare(path)
  path = path or vim.fn.getcwd()
  local fwt = vim.split(vim.fn.system('cd ' .. vim.fn.fnameescape(path) .. ' && git worktree list'), '\n')[1]

  if fwt:sub(#fwt - 5) == '(bare)' then
    return true, fwt:gsub('%(bare%)$', ''):gsub('[ ]*$', '')
  else
    return false, nil
  end
end

return M
