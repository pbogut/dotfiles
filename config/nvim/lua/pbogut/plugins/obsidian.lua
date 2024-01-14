---@type LazyPluginSpec
return {
  'epwalsh/obsidian.nvim',
  keys = {
    { '<space>fN', '<cmd>Notes<cr>' },
  },
  cmd = { 'Notes', 'NToday' },
  ft = { 'markdown' },
  opts = {
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
      return parts[1]
    end,
  },
  config = function(_, opts)
    local command = vim.api.nvim_create_user_command
    local obsidian = require('obsidian')

    obsidian.setup(opts)

    local obsidian_commands = require('obsidian.command')
    -- create note relative to current note when following new link
    local follow = false
    local cmd_new = obsidian_commands.new
    obsidian_commands.new = function(client, data)
      if follow then
        follow = false
        local note = client:new_note(data.args, nil, vim.fn.expand('%:h'))
        vim.api.nvim_command('e ' .. tostring(note.path))
      else
        cmd_new(client, data)
      end
    end

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

    vim.keymap.set('n', 'gf', function()
      if obsidian.util.cursor_on_markdown_link() then
        follow = true
        return '<cmd>ObsidianFollowLink<cr>'
      else
        return 'gf'
      end
    end, { noremap = false, expr = true })
  end,
}
