return {
  enabled = false,
  'glacambre/firenvim',

  -- Lazy load firenvim
  -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
  -- cond = not not vim.g.started_by_firenvim,
  cmd = "FirenvimInstall",
  build = function()
    require('lazy').load({ plugins = 'firenvim', wait = true })
    vim.fn['firenvim#install'](0)
  end,
  config = function()
    vim.cmd([[command! FirenvimInstall :call firenvim#install(0)]])
  end,
}
