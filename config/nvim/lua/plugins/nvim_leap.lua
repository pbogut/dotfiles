local u = require('utils')
local leap = require('leap')

leap.setup({
  safe_labels = { 'y', 'p', 'q', 's', 'f', 'n', 'u', 't', '/' },
  labels = {
    'p', 'q', 's', 'f', 'n', 'j', 'k', 'l', 'h', 'o', 'd', 'w', 'e',
    'm', 'b', 'u', 'y', 'v', 'r', 'g', 't', 'c', 'x', '/', 'z'
  },
  special_keys = {
    repeat_search = '<nop>',
    next_phase_one_target = '<nop>',
    next_target = {';'},
    prev_target = {','},
    next_group = '<enter>',
    prev_group = '<space>',
    multi_accept = '<nop>',
    multi_revert = '<nop>',
  }
})

--[[ local function leap_cur() ]]
--[[   require('leap').leap({ target_windows = { vim.fn.win_getid() } }) ]]
--[[ end ]]

local function leap_all()
  require('leap').leap({
    target_windows = vim.tbl_filter(function(win)
      return vim.api.nvim_win_get_config(win).focusable
    end, vim.api.nvim_tabpage_list_wins(0)),
  })
end

local maps = {
  { { 'n', 'x', 'o' }, 's', '<Plug>(leap-forward-to)', 'Leap current window' },
  { { 'n', 'x', 'o' }, 'S', '<Plug>(leap-backward-to)', 'Leap current window' },
  { { 'n', 'x', 'o' }, '<space>S', leap_all, 'Leap all visible windows' },
}

for _, map in ipairs(maps) do
  local modes = map[1]
  local lhs = map[2]
  local rhs = map[3]
  local desc = map[4]
  for _, mode in ipairs(modes) do
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
  end
end

u.highlights({
  LeapLabelPrimary = { link = 'Search' },
})
--[[ LeapLabelSecondary
LeapLabelSelected
LeapLabelPrimary
LeapMatch ]]
