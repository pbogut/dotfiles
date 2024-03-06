---@type LazyPluginSpec
return {
  'stevearc/profile.nvim',
  keys = { { '<f1>', '<plug>(profile-toggle)' } },
  config = function()
    local function toggle_profile()
      local prof = require('profile')
      if prof.is_recording() then
        prof.stop()
        vim.ui.input({ prompt = 'Save profile to:', completion = 'file', default = 'profile.json' }, function(filename)
          if filename then
            prof.export(filename)
            vim.notify(string.format('Wrote %s', filename))
          end
        end)
      else
        ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
        prof.start('*')
      end
    end
    vim.keymap.set('', '<plug>(profile-toggle)', toggle_profile)
  end,
}
