require('gitsigns').setup({
  --[[ sign_priority = 1, ]]
  preview_config = {
    -- Options passed to nvim_open_win
    border = 'none',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
})

local k = vim.keymap

k.set('n', '<space>hh', '<cmd>Gitsigns toggle_linehl<cr>')

k.set('n', '<space>hr', '<cmd>Gitsigns refresh<cr>')
k.set('n', '<space>hd', '<cmd>Gitsigns preview_hunk<cr>')
k.set('n', '<space>hR', '<cmd>Gitsigns reset_hunk<cr>')
k.set('n', '<space>hs', '<cmd>Gitsigns stage_hunk<cr>')
k.set('n', '<space>hu', '<cmd>Gitsigns undo_stage_hunk<cr>')
k.set('n', '<space>gd', '<cmd>Gitsigns diffthis<cr>')
k.set('n', '<space>hb', '<cmd>Gitsigns blame_line<cr>')

k.set('n', ']h', '<cmd>Gitsigns next_hunk<cr>')
k.set('n', '[h', '<cmd>Gitsigns prev_hunk<cr>')

local u = require('utils')
local c = vim.g.colors

u.highlights({
  GitSignsAddLn = { guifg = c.green },
  GitSignsDeleteLn = { guifg = c.red },
  --[[ MyGitSignsChangeLn = { guifg = c.ad_info }, ]]
})
