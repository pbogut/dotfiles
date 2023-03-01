local setup = function()
  vim.g.matchup_matchparen_offscreen = { method = 'status_manual' }
  vim.g.matchup_motion_enabled = 0
end

local config = function()
  vim.keymap.set('n', '%', '<plug>(matchup-%)', {
    silent = true,
    noremap = true,
  })
  vim.keymap.set('n', '[%', '<plug>(matchup-[%)', {
    silent = true,
    noremap = true,
  })
  vim.keymap.set('n', ']%', '<plug>(matchup-]%)', {
    silent = true,
    noremap = true,
  })
end

return {
  config = config,
  setup = setup,
}
