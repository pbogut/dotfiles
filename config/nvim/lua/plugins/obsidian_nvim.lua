local command = vim.api.nvim_create_user_command
local obsidian = require('obsidian')
obsidian.setup({
  dir = '~/Wiki',
  completion = {
    nvim_cmp = true, -- if using nvim-cmp, otherwise set to false
  },
  follow_url_func = function(url)
    vim.fn.jobstart({ 'gio', 'open', url }, { detach = true })
  end,
  templates = {
    subdir = 'templates',
  },
  disable_frontmatter = true,
  daily_notes = {
    folder = 'daily_notes/',
    template = 'daily',
  },
  note_id_func = function(title)
    local parts = vim.split(title, '|')
    local file_name = parts[1]

    return vim.fn.expand('%:h') .. '/' .. file_name
  end,
})

command('Notes', function()
  local builtin = require('telescope.builtin')
  builtin.find_files({
    cwd = os.getenv('HOME') .. '/Wiki',
    no_ignore_parent = true,
  })
end, {})
command('NToday', function()
  vim.cmd.edit('~/Wiki/daily_notes/' .. os.date('%Y-%m-%d') .. '.md')
end, {})
vim.keymap.set('n', '<space>fN', '<cmd>Notes<cr>', { noremap = true })
vim.keymap.set('n', 'gf', function()
  if obsidian.util.cursor_on_markdown_link() then
    return '<cmd>ObsidianFollowLink<CR>'
  else
    return 'gf'
  end
end, { noremap = false, expr = true })
