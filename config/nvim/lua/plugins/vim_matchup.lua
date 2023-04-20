local setup = function()
  vim.g.matchup_matchparen_offscreen = { method = 'status_manual' }
  vim.keymap.set('i', '<plug>(disable_matchup-c_g)', '<plug>(matchup-c_g%)', {
    silent = true,
    noremap = true,
  })
end

local config = function() end

return {
  config = config,
  setup = setup,
}
