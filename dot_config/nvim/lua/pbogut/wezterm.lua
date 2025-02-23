local M = {}

function M.split_pane(opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()

  vim.fn.jobstart('wezterm cli split-pane --cwd ' .. vim.fn.shellescape(cwd), { detach = true })
end
return M
